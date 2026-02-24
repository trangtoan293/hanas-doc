import React from 'react';
import styles from './styles.module.css';

export default function HeroSection(): JSX.Element {
  return (
    <section className={styles.hero}>
      <div className="container">
        <div className={styles.heroInner}>
          <div className={styles.heroContent}>
            <h1 className={styles.heroTitle}>
              Kho Dữ Liệu Thông Minh
              <br />
              Một Nền Tảng, Mọi Dữ Liệu
            </h1>
            <p className={styles.heroSubtitle}>
              Hanas Data Platform kết hợp sức mạnh của Data Lake và Data Warehouse,
              giúp doanh nghiệp quản lý và khai thác dữ liệu hiệu quả.
            </p>
            <div className={styles.heroButtons}>
              <a href="/" className="button--primary">
                KHÁM PHÁ NGAY
              </a>
              <a href="/overview/architecture" className="button--link">
                Tìm hiểu kiến trúc
                <span className="link-arrow">→</span>
              </a>
            </div>
          </div>
          <div className={styles.heroVisual}>
            <div className={styles.visualPlaceholder} />
          </div>
        </div>
      </div>
    </section>
  );
}
