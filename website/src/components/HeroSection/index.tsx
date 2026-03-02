import React from 'react';
import styles from './styles.module.css';

export default function HeroSection(): React.JSX.Element {
  return (
    <section className={styles.hero}>
      <div className="container">
        <div className={styles.heroInner}>
          <div className={styles.heroContent}>
            <span className={styles.badge}>Data Lakehouse Platform</span>
            <h2 className={styles.heroEyebrow}>Hanas Data Platform</h2>
            <h1 className={styles.heroTitle}>
              Một Nền Tảng. Mọi Dữ Liệu.
            </h1>
            <p className={styles.heroSubtitle}>
              Hanas Data Platform kết hợp sức mạnh của Data Lake và Data Warehouse,
              giúp doanh nghiệp quản lý và khai thác dữ liệu hiệu quả.
            </p>
            <div className={styles.heroButtons}>
              <a href="https://portal.hanas.io/portal/home/dashboard" className="button--primary">
                KHÁM PHÁ NGAY
              </a>
              <a href="/overview/architecture" className="button--link">
                Tìm hiểu kiến trúc
                <span className="link-arrow">→</span>
              </a>
            </div>
          </div>
          <div className={styles.heroVisual}>
            <img
              src="/img/hanas_platform.png"
              alt="Hanas Data Platform Architecture"
              className={styles.heroImage}
            />
          </div>
        </div>
      </div>
    </section>
  );
}
