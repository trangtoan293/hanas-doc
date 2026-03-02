import React, { useState } from 'react';
import styles from './styles.module.css';

interface CTABannerProps {
  title?: string;
}

const NewsletterForm: React.FC = () => {
  const [email, setEmail] = useState('');
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (email.trim()) {
      setSubmitted(true);
      setEmail('');
      // Reset success message after 5 seconds
      setTimeout(() => setSubmitted(false), 5000);
    }
  };

  return (
    <div className={styles.newsletter}>
      <p className={styles.newsletterText}>
        Nhận tin tức và cập nhật mới nhất
      </p>
      <p className={styles.newsletterSubtext}>
        Đăng ký để nhận thông tin về sản phẩm và tài nguyên mới
      </p>
      <form className={styles.newsletterForm} onSubmit={handleSubmit}>
        <input 
          type="email" 
          placeholder="Nhập email của bạn"
          className={styles.emailInput}
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
        <button type="submit" className={styles.newsletterButton}>
          ĐĂNG KÝ
        </button>
      </form>
      {submitted && (
        <p className={styles.successMessage}>
          Đăng ký thành công! Cảm ơn bạn.
        </p>
      )}
    </div>
  );
};

const CTABanner: React.FC<CTABannerProps> = ({ 
  title = "Bắt đầu với Hanas ngay hôm nay" 
}) => {
  const checklistItems = [
    'Bản dùng thử 30 ngày miễn phí',
    'Không cần thẻ tín dụng',
    'Hủy bất cứ lúc nào'
  ];

  return (
    <section className={styles.ctaBanner}>
      <div className={styles.container}>
        <div className={styles.content}>
          <h2 className={styles.title}>{title}</h2>
          
          <ul className={styles.checklist}>
            {checklistItems.map((item, index) => (
              <li key={index} className={styles.checklistItem}>
                <svg 
                  className={styles.checkIcon} 
                  viewBox="0 0 24 24" 
                  fill="none" 
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2"/>
                  <path 
                    d="M8 12L11 15L16 9" 
                    stroke="currentColor" 
                    strokeWidth="2" 
                    strokeLinecap="round" 
                    strokeLinejoin="round"
                  />
                </svg>
                <span className={styles.checklistText}>{item}</span>
              </li>
            ))}
          </ul>

          <div className={styles.buttonGroup}>
            <a 
              href="https://portal.hanas.io/portal/home/dashboard"
              className={styles.buttonPrimary}
            >
              BẮT ĐẦU MIỄN PHÍ
            </a>
            <a 
              href="/overview"
              className={styles.buttonSecondary}
            >
              XEM DEMO
            </a>
          </div>
        </div>

        <NewsletterForm />
      </div>
    </section>
  );
};

export default CTABanner;
