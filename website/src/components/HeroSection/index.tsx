import React from 'react';
import styles from './styles.module.css';

export default function HeroSection(): React.JSX.Element {
  return (
    <section className={styles.hero}>
      {/* Background decorative gradient blobs */}
      <div className={styles.bgBlob1} aria-hidden="true" />
      <div className={styles.bgBlob2} aria-hidden="true" />
      <div className={styles.bgBlob3} aria-hidden="true" />

      <div className="container">
        <div className={styles.heroInner}>
          {/* Left: Text Content */}
          <div className={styles.heroContent}>

            <p className={`${styles.heroEyebrow} ${styles.animateIn} ${styles.delay1}`}>
              <span className={styles.eyebrowHighlight}>Hanas</span> Data Platform
            </p>

            <h1 className={`${styles.heroTitle} ${styles.animateIn} ${styles.delay2}`}>
              Một Nền Tảng.<br />
              <span className={styles.gradientText}>Mọi Dữ Liệu.</span>
            </h1>

            <p className={`${styles.heroSubtitle} ${styles.animateIn} ${styles.delay3}`}>
              Hanas Data Platform kết hợp sức mạnh của Data Lake và Data Warehouse,
              giúp doanh nghiệp quản lý và khai thác dữ liệu hiệu quả.
            </p>

            <div className={`${styles.heroButtons} ${styles.animateIn} ${styles.delay4}`}>
              <a
                href="https://portal.hanas.io/portal/home/dashboard"
                className={styles.ctaPrimary}
              >
                <span className={styles.ctaShimmer} />
                KHÁM PHÁ NGAY
              </a>
              <a href="/overview/architecture" className={styles.ctaLink}>
                Tìm hiểu kiến trúc
                <span className={styles.ctaArrow}>→</span>
              </a>
            </div>

            {/* Trust indicators */}
            <div className={`${styles.trustRow} ${styles.animateIn} ${styles.delay5}`}>
              <div className={styles.trustItem}>
                <svg className={styles.trustIcon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                  <path d="M9 12l2 2 4-4" />
                </svg>
                <div>
                  <span className={styles.trustNumber}>Enterprise</span>
                  <span className={styles.trustLabel}>Ready</span>
                </div>
              </div>
            </div>
          </div>

          {/* Right: Hero Visual */}
          <div className={`${styles.heroVisual} ${styles.animateIn} ${styles.delay4}`}>
            <div className={styles.heroGlow} aria-hidden="true" />
            <img
              src="/img/hanas_platform.png"
              alt="Hanas Data Platform Architecture"
              className={styles.heroImage}
              loading="eager"
            />
          </div>
        </div>
      </div>
    </section>
  );
}
