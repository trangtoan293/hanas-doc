import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

import logging 
import json
from typing import List, Dict
from datetime import datetime

class EmailNotificationService:
    """Service class for sending email notifications"""
    
    def __init__(self, variable:Dict = None):
        # Email configuration - store in Airflow Variables for security
        self.smtp_server = variable['SMTP_SERVER']
        self.smtp_port = int(variable['SMTP_PORT'])
        self.sender_email = variable['SENDER_EMAIL'] # Required variable
        self.sender_password = variable['SENDER_PASSWORD']  # Required variable
        self.default_notification_email = variable['DEFAULT_NOTIFICATION_EMAIL']
        # Email templates
        self.success_template = """
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .header {{ background-color: #4CAF50; color: white; padding: 20px; text-align: center; }}
                .content {{ padding: 20px; }}
                .summary {{ background-color: #f9f9f9; padding: 15px; border-left: 4px solid #4CAF50; margin: 20px 0; }}
                .file-list {{ margin: 15px 0; }}
                .file-item {{ padding: 8px; background-color: #e8f5e8; margin: 5px 0; border-radius: 4px; }}
                .stats {{ display: inline-block; margin: 10px; padding: 10px; background-color: #f0f8ff; border-radius: 5px; }}
                .footer {{ margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h2>🎉 OCR Processing Completed Successfully</h2>
            </div>
            
            <div class="content">
                <p>Xin chào,</p>
                
                <p>Hệ thống OCR đã xử lý thành công các tài liệu của bạn. Dưới đây là thông tin chi tiết:</p>
                
                <div class="summary">
                    <h3>📊 Tóm tắt xử lý:</h3>
                    <div class="stats">
                        <strong>Số file đã xử lý:</strong> {total_files}
                    </div>
                    <div class="stats">
                        <strong>Tổng ký tự trích xuất:</strong> {total_characters:,}
                    </div>
                    <div class="stats">
                        <strong>Tổng bảng phát hiện:</strong> {total_tables}
                    </div>
                    <div class="stats">
                        <strong>Tổng đoạn văn:</strong> {total_paragraphs}
                    </div>
                    <div class="stats">
                        <strong>Thời gian xử lý:</strong> {processing_time}
                    </div>
                </div>
                
                <h3>📄 Danh sách file đã xử lý:</h3>
                <div class="file-list">
                    {file_details}
                </div>
                
                <h3>🔍 Thông tin kỹ thuật:</h3>
                <ul>
                    <li><strong>DAG ID:</strong> {dag_id}</li>
                    <li><strong>Task Instance:</strong> {task_instance_id}</li>
                    <li><strong>Execution Date:</strong> {execution_date}</li>
                    <li><strong>OCR Engine:</strong> K-DIP API v1</li>
                    <li><strong>Enhanced LLM:</strong> ✅ Enabled</li>
                    <li><strong>Chart Description:</strong> ✅ Enabled</li>
                </ul>
                
                <p>Dữ liệu đã được lưu trữ thành công vào Iceberg table và sẵn sàng cho các bước xử lý tiếp theo.</p>
                
                <div class="footer">
                    <p>Email này được gửi tự động từ hệ thống OCR Pipeline.<br>
                    Thời gian gửi: {send_time}<br>
                    Nếu có thắc mắc, vui lòng liên hệ team Data Engineering.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        self.error_template = """
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .header {{ background-color: #f44336; color: white; padding: 20px; text-align: center; }}
                .content {{ padding: 20px; }}
                .error-details {{ background-color: #fff5f5; padding: 15px; border-left: 4px solid #f44336; margin: 20px 0; }}
                .footer {{ margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h2>❌ OCR Processing Failed</h2>
            </div>
            
            <div class="content">
                <p>Xin chào,</p>
                
                <p>Hệ thống OCR gặp lỗi khi xử lý tài liệu. Vui lòng kiểm tra và thực hiện lại.</p>
                
                <div class="error-details">
                    <h3>🚨 Chi tiết lỗi:</h3>
                    <p><strong>Error Message:</strong> {error_message}</p>
                    <p><strong>DAG ID:</strong> {dag_id}</p>
                    <p><strong>Task Instance:</strong> {task_instance_id}</p>
                    <p><strong>Execution Date:</strong> {execution_date}</p>
                    <p><strong>Failed Files:</strong> {failed_files}</p>
                </div>
                
                <p>Vui lòng liên hệ team Data Engineering để được hỗ trợ.</p>
                
                <div class="footer">
                    <p>Email này được gửi tự động từ hệ thống OCR Pipeline.<br>
                    Thời gian gửi: {send_time}</p>
                </div>
            </div>
        </body>
        </html>
        """
    
    def send_success_notification(self, processing_results: List[Dict], context: Dict):
        """Send success notification email"""
        try:
            # Calculate summary statistics
            total_files = len(processing_results)
            total_characters = sum(result.get('text_length', [0]) for result in processing_results)
            total_tables = sum(result.get('total_tables', [0]) for result in processing_results)
            total_paragraphs = sum(result.get('total_paragraphs', [0]) for result in processing_results)
            
            # Generate file details HTML
            file_details_html = ""
            for i, result in enumerate(processing_results, 1):
                text_length = result.get('text_length', [0])
                tables = result.get('total_tables', [0])
                chunks = result.get('total_chunks', [0])
                
                file_details_html += f"""
                <div class="file-item">
                    <strong>File {i}:</strong> {text_length:,} ký tự | {tables} bảng | {chunks} chunks
                </div>
                """
            
            # Get execution context
            dag_id = context.get('dag').dag_id
            task_instance_id = context.get('task_instance_key_str', 'N/A')
            execution_date = context.get('execution_date', 'N/A')
            start_time = context.get('dag_run').start_date
            end_time = datetime.now()
            processing_time = datetime.now() #str(end_time - start_time) if start_time else 'N/A'
            
            # Format email content
            email_content = self.success_template.format(
                total_files=total_files,
                total_characters=total_characters,
                total_tables=total_tables,
                total_paragraphs=total_paragraphs,
                processing_time=processing_time,
                file_details=file_details_html,
                dag_id=dag_id,
                task_instance_id=task_instance_id,
                execution_date=execution_date,
                send_time=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            )
            
            # Get recipient email from DAG config or use default
            recipient_email = self.default_notification_email
            
            subject = f"✅ OCR Processing Success - {total_files} files processed"
            
            self._send_email(recipient_email, subject, email_content)
            logging.info(f"Success notification sent to {recipient_email}")
            
        except Exception as e:
            logging.error(f"Failed to send success notification: {str(e)}")
            # Don't raise exception to avoid failing the DAG
    
    def send_error_notification(self, error_message: str, failed_files: List[str], context: Dict):
        """Send error notification email"""
        try:
            # Get execution context
            dag_id = context.get('dag').dag_id
            task_instance_id = context.get('task_instance_key_str', 'N/A')
            execution_date = context.get('execution_date', 'N/A')
            
            # Format email content
            email_content = self.error_template.format(
                error_message=error_message,
                dag_id=dag_id,
                task_instance_id=task_instance_id,
                execution_date=execution_date,
                failed_files=', '.join(failed_files),
                send_time=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            )
            
            # Get recipient email from DAG config or use default
            recipient_email = self.default_notification_email
            subject = f"❌ OCR Processing Failed - {dag_id}"
            
            self._send_email(recipient_email, subject, email_content)
            logging.info(f"Error notification sent to {recipient_email}")
            
        except Exception as e:
            logging.error(f"Failed to send error notification: {str(e)}")
    
    def _send_email(self, recipient_email: str, subject: str, html_content: str):
        """Send email using SMTP"""
        try:
            # Create message
            message = MIMEMultipart("alternative")
            message["Subject"] = subject
            message["From"] = self.sender_email
            message["To"] = recipient_email
            
            # Add HTML content
            html_part = MIMEText(html_content, "html", "utf-8")
            message.attach(html_part)
            
            # Create secure connection and send email
            context = ssl.create_default_context()
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls(context=context)
                server.login(self.sender_email, self.sender_password)
                server.sendmail(self.sender_email, recipient_email, message.as_string())
            
            logging.info(f"Email sent successfully to {recipient_email}")
            
        except Exception as e:
            logging.error(f"SMTP error: {str(e)}")
            raise

