# -*- coding: utf-8 -*-
"""
域名邮箱管理器 - 邮箱验证处理器
从cursor-auto-free项目提取并重构的邮箱验证核心功能
"""

import logging
import time
import re
import email
import imaplib
import poplib
import requests
from datetime import datetime
from email.parser import Parser
from typing import Optional, Tuple, Dict, Any

from models.config_model import ConfigModel
from utils.logger import get_logger


class EmailVerificationHandler:
    """
    邮箱验证处理器
    
    支持多种验证方式：
    - tempmail.plus API
    - IMAP协议
    - POP3协议
    """

    def __init__(self, config: ConfigModel, account: str):
        """
        初始化邮箱验证处理器
        
        Args:
            config: 配置模型实例
            account: 要验证的邮箱账户
        """
        self.config = config
        self.account = account
        self.logger = get_logger(__name__)
        self.session = requests.Session()
        
        # 设置请求超时
        self.session.timeout = config.tempmail_config.api_timeout
        
        self.logger.info(f"初始化邮箱验证处理器: {account}")

    def get_verification_code(self, max_retries: int = 5, retry_interval: int = 60) -> Optional[str]:
        """
        获取验证码，带有重试机制
        
        Args:
            max_retries: 最大重试次数
            retry_interval: 重试间隔时间（秒）
            
        Returns:
            验证码字符串，如果获取失败则返回None
        """
        verification_method = self.config.get_verification_method()
        
        for attempt in range(max_retries):
            try:
                self.logger.info(f"尝试获取验证码 (第 {attempt + 1}/{max_retries} 次)，使用方法: {verification_method}")
                
                if verification_method == "tempmail":
                    verify_code, first_id = self._get_latest_mail_code()
                    if verify_code is not None and first_id is not None:
                        self._cleanup_mail(first_id)
                        return verify_code
                        
                elif verification_method == "imap":
                    if self.config.imap_config.protocol.upper() == "IMAP":
                        verify_code = self._get_mail_code_by_imap()
                    else:
                        verify_code = self._get_mail_code_by_pop3()
                    if verify_code is not None:
                        return verify_code
                        
                else:
                    self.logger.error(f"不支持的验证方式: {verification_method}")
                    return None
                
                if attempt < max_retries - 1:  # 除了最后一次尝试，都等待
                    self.logger.warning(f"未获取到验证码，{retry_interval} 秒后重试...")
                    time.sleep(retry_interval)
                    
            except Exception as e:
                self.logger.error(f"获取验证码失败: {e}")
                if attempt < max_retries - 1:
                    self.logger.error(f"发生错误，{retry_interval} 秒后重试...")
                    time.sleep(retry_interval)
                else:
                    raise Exception(f"获取验证码失败且已达最大重试次数: {e}") from e
        
        raise Exception(f"经过 {max_retries} 次尝试后仍未获取到验证码")

    def _get_mail_code_by_imap(self, retry: int = 0) -> Optional[str]:
        """
        使用IMAP协议获取邮件验证码
        
        Args:
            retry: 重试次数
            
        Returns:
            验证码字符串或None
        """
        if retry > 0:
            time.sleep(3)
        if retry >= 20:
            raise Exception("获取验证码超时")
            
        try:
            imap_config = self.config.imap_config
            
            # 连接到IMAP服务器
            mail = imaplib.IMAP4_SSL(imap_config.server, imap_config.port)
            mail.login(imap_config.username, imap_config.password)
            
            search_by_date = False
            
            # 针对网易系邮箱的特殊处理
            if imap_config.username.endswith(('@163.com', '@126.com', '@yeah.net')):
                imap_id = (
                    "name", imap_config.username.split('@')[0], 
                    "contact", imap_config.username, 
                    "version", "1.0.0", 
                    "vendor", "email-domain-manager"
                )
                mail.xatom('ID', '("' + '" "'.join(imap_id) + '")')
                search_by_date = True
                
            mail.select(imap_config.inbox_dir)
            
            if search_by_date:
                date = datetime.now().strftime("%d-%b-%Y")
                status, messages = mail.search(None, f'ON {date} UNSEEN')
            else:
                status, messages = mail.search(None, 'TO', '"' + self.account + '"')
                
            if status != 'OK':
                return None
                
            mail_ids = messages[0].split()
            if not mail_ids:
                # 没有获取到，递归重试
                return self._get_mail_code_by_imap(retry=retry + 1)
                
            for mail_id in reversed(mail_ids):
                status, msg_data = mail.fetch(mail_id, '(RFC822)')
                if status != 'OK':
                    continue
                    
                raw_email = msg_data[0][1]
                email_message = email.message_from_bytes(raw_email)
                
                # 如果是按日期搜索的邮件，需要进一步核对收件人地址
                if search_by_date and email_message['to'] != self.account:
                    continue
                    
                body = self._extract_imap_body(email_message)
                if body:
                    # 避免6位数字的域名被误识别成验证码
                    body = body.replace(self.account, '')
                    code_match = re.search(r"\b\d{6}\b", body)
                    if code_match:
                        code = code_match.group()
                        # 删除找到验证码的邮件
                        mail.store(mail_id, '+FLAGS', '\\Deleted')
                        mail.expunge()
                        mail.logout()
                        return code
                        
            mail.logout()
            return None
            
        except Exception as e:
            self.logger.error(f"IMAP获取邮件失败: {e}")
            return None

    def _extract_imap_body(self, email_message) -> str:
        """
        提取IMAP邮件正文
        
        Args:
            email_message: 邮件消息对象
            
        Returns:
            邮件正文字符串
        """
        if email_message.is_multipart():
            for part in email_message.walk():
                content_type = part.get_content_type()
                content_disposition = str(part.get("Content-Disposition"))
                if content_type == "text/plain" and "attachment" not in content_disposition:
                    charset = part.get_content_charset() or 'utf-8'
                    try:
                        body = part.get_payload(decode=True).decode(charset, errors='ignore')
                        return body
                    except Exception as e:
                        self.logger.error(f"解码邮件正文失败: {e}")
        else:
            content_type = email_message.get_content_type()
            if content_type == "text/plain":
                charset = email_message.get_content_charset() or 'utf-8'
                try:
                    body = email_message.get_payload(decode=True).decode(charset, errors='ignore')
                    return body
                except Exception as e:
                    self.logger.error(f"解码邮件正文失败: {e}")
        return ""

    def _get_mail_code_by_pop3(self, retry: int = 0) -> Optional[str]:
        """
        使用POP3协议获取邮件验证码
        
        Args:
            retry: 重试次数
            
        Returns:
            验证码字符串或None
        """
        if retry > 0:
            time.sleep(3)
        if retry >= 20:
            raise Exception("获取验证码超时")
            
        pop3 = None
        try:
            imap_config = self.config.imap_config
            
            # 连接到服务器
            pop3 = poplib.POP3_SSL(imap_config.server, int(imap_config.port))
            pop3.user(imap_config.username)
            pop3.pass_(imap_config.password)
            
            # 获取最新的10封邮件
            num_messages = len(pop3.list()[1])
            for i in range(num_messages, max(1, num_messages-9), -1):
                response, lines, octets = pop3.retr(i)
                msg_content = b'\r\n'.join(lines).decode('utf-8')
                msg = Parser().parsestr(msg_content)
                
                # 检查发件人
                if 'no-reply@cursor.sh' in msg.get('From', ''):
                    # 提取邮件正文
                    body = self._extract_pop3_body(msg)
                    if body:
                        # 查找验证码
                        code_match = re.search(r"\b\d{6}\b", body)
                        if code_match:
                            code = code_match.group()
                            pop3.quit()
                            return code
                            
            pop3.quit()
            return self._get_mail_code_by_pop3(retry=retry + 1)
            
        except Exception as e:
            self.logger.error(f"POP3获取邮件失败: {e}")
            if pop3:
                try:
                    pop3.quit()
                except:
                    pass
            return None

    def _extract_pop3_body(self, email_message) -> str:
        """
        提取POP3邮件正文
        
        Args:
            email_message: 邮件消息对象
            
        Returns:
            邮件正文字符串
        """
        if email_message.is_multipart():
            for part in email_message.walk():
                content_type = part.get_content_type()
                content_disposition = str(part.get("Content-Disposition"))
                if content_type == "text/plain" and "attachment" not in content_disposition:
                    try:
                        body = part.get_payload(decode=True).decode('utf-8', errors='ignore')
                        return body
                    except Exception as e:
                        self.logger.error(f"解码邮件正文失败: {e}")
        else:
            try:
                body = email_message.get_payload(decode=True).decode('utf-8', errors='ignore')
                return body
            except Exception as e:
                self.logger.error(f"解码邮件正文失败: {e}")
        return ""

    def _get_latest_mail_code(self) -> Tuple[Optional[str], Optional[str]]:
        """
        从tempmail.plus获取最新邮件验证码

        Returns:
            (验证码, 邮件ID) 的元组，失败时返回 (None, None)
        """
        try:
            tempmail_config = self.config.tempmail_config

            # 获取邮件列表
            mail_list_url = (
                f"https://tempmail.plus/api/mails?"
                f"email={tempmail_config.username}{tempmail_config.extension}&"
                f"limit=20&epin={tempmail_config.epin}"
            )

            mail_list_response = self.session.get(mail_list_url)
            mail_list_data = mail_list_response.json()
            time.sleep(0.5)

            if not mail_list_data.get("result"):
                return None, None

            # 获取最新邮件的ID
            first_id = mail_list_data.get("first_id")
            if not first_id:
                return None, None

            # 获取具体邮件内容
            mail_detail_url = (
                f"https://tempmail.plus/api/mails/{first_id}?"
                f"email={tempmail_config.username}{tempmail_config.extension}&"
                f"epin={tempmail_config.epin}"
            )

            mail_detail_response = self.session.get(mail_detail_url)
            mail_detail_data = mail_detail_response.json()
            time.sleep(0.5)

            if not mail_detail_data.get("result"):
                return None, None

            # 从邮件文本中提取6位数字验证码
            mail_text = mail_detail_data.get("text", "")
            mail_subject = mail_detail_data.get("subject", "")

            self.logger.info(f"找到邮件主题: {mail_subject}")

            # 修改正则表达式，确保6位数字不紧跟在字母或域名相关符号后面
            code_match = re.search(r"(?<![a-zA-Z@.])\b\d{6}\b", mail_text)

            if code_match:
                return code_match.group(), first_id
            return None, None

        except Exception as e:
            self.logger.error(f"从tempmail获取验证码失败: {e}")
            return None, None

    def _cleanup_mail(self, first_id: str) -> bool:
        """
        清理tempmail邮件

        Args:
            first_id: 邮件ID

        Returns:
            是否清理成功
        """
        try:
            tempmail_config = self.config.tempmail_config

            # 构造删除请求的URL和数据
            delete_url = "https://tempmail.plus/api/mails/"
            payload = {
                "email": f"{tempmail_config.username}{tempmail_config.extension}",
                "first_id": first_id,
                "epin": tempmail_config.epin,
            }

            # 最多尝试5次
            for _ in range(5):
                response = self.session.delete(delete_url, data=payload)
                try:
                    result = response.json().get("result")
                    if result is True:
                        self.logger.debug(f"成功清理邮件: {first_id}")
                        return True
                except:
                    pass

                # 如果失败，等待0.5秒后重试
                time.sleep(0.5)

            self.logger.warning(f"清理邮件失败: {first_id}")
            return False

        except Exception as e:
            self.logger.error(f"清理邮件异常: {e}")
            return False

    def test_connection(self) -> Dict[str, Any]:
        """
        测试连接配置

        Returns:
            测试结果字典，包含状态和详细信息
        """
        verification_method = self.config.get_verification_method()
        result = {
            "success": False,
            "method": verification_method,
            "message": "",
            "details": {}
        }

        try:
            if verification_method == "tempmail":
                result.update(self._test_tempmail_connection())
            elif verification_method == "imap":
                result.update(self._test_imap_connection())
            else:
                result["message"] = f"不支持的验证方式: {verification_method}"

        except Exception as e:
            result["message"] = f"测试连接失败: {e}"
            self.logger.error(f"测试连接异常: {e}")

        return result

    def _test_tempmail_connection(self) -> Dict[str, Any]:
        """测试tempmail连接"""
        try:
            tempmail_config = self.config.tempmail_config

            # 测试API连接
            test_url = (
                f"https://tempmail.plus/api/mails?"
                f"email={tempmail_config.username}{tempmail_config.extension}&"
                f"limit=1&epin={tempmail_config.epin}"
            )

            response = self.session.get(test_url, timeout=10)
            data = response.json()

            if data.get("result") is not None:
                return {
                    "success": True,
                    "message": "TempMail连接测试成功",
                    "details": {
                        "email": f"{tempmail_config.username}{tempmail_config.extension}",
                        "status_code": response.status_code
                    }
                }
            else:
                return {
                    "success": False,
                    "message": "TempMail API返回错误",
                    "details": {"response": data}
                }

        except Exception as e:
            return {
                "success": False,
                "message": f"TempMail连接失败: {e}",
                "details": {}
            }

    def _test_imap_connection(self) -> Dict[str, Any]:
        """测试IMAP连接"""
        try:
            imap_config = self.config.imap_config

            if imap_config.protocol.upper() == "IMAP":
                # 测试IMAP连接
                mail = imaplib.IMAP4_SSL(imap_config.server, imap_config.port)
                mail.login(imap_config.username, imap_config.password)
                mail.select(imap_config.inbox_dir)
                mail.logout()

                return {
                    "success": True,
                    "message": "IMAP连接测试成功",
                    "details": {
                        "server": imap_config.server,
                        "port": imap_config.port,
                        "username": imap_config.username,
                        "inbox": imap_config.inbox_dir
                    }
                }
            else:
                # 测试POP3连接
                pop3 = poplib.POP3_SSL(imap_config.server, int(imap_config.port))
                pop3.user(imap_config.username)
                pop3.pass_(imap_config.password)
                pop3.quit()

                return {
                    "success": True,
                    "message": "POP3连接测试成功",
                    "details": {
                        "server": imap_config.server,
                        "port": imap_config.port,
                        "username": imap_config.username
                    }
                }

        except Exception as e:
            return {
                "success": False,
                "message": f"邮箱服务器连接失败: {e}",
                "details": {}
            }

    def __del__(self):
        """析构函数，清理资源"""
        try:
            if hasattr(self, 'session'):
                self.session.close()
        except:
            pass
