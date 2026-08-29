import React from 'react';
import useLazyVideo from '@site/src/hooks/useLazyVideo';
import styles from './styles.module.css';

export default function HeroSection(): React.JSX.Element {
  const videoRef = useLazyVideo();
  return (
    <section className={styles.hero}>
      <video
        className={styles.stageVideo}
        ref={videoRef}
        muted
        loop
        playsInline
        preload="none"
        poster="/img/landing/use-case-analytics.webp"
        aria-hidden="true"
      >
        <source src="/video/main-background.mp4" type="video/mp4" />
      </video>
      <div className={styles.gridBackdrop} aria-hidden="true" />
      <div className={styles.heroGlow} aria-hidden="true" />

      <div className={`container ${styles.heroContainer}`}>
        <div className={styles.heroInner}>
          <div className={styles.heroContent}>
            <span className={`${styles.heroEyebrow} ${styles.animateIn} ${styles.delay1}`}>
              Data &amp; AI Platform
            </span>

            <h1 className={`${styles.heroTitle} ${styles.animateIn} ${styles.delay2}`}>
              Kết nối mọi nguồn dữ liệu
              <span className={styles.gradientText}>cho phân tích và AI.</span>
            </h1>

            <p className={`${styles.heroSubtitle} ${styles.animateIn} ${styles.delay3}`}>
              Doanh nghiệp có một nguồn dữ liệu tin cậy cho BI, analytics và AI. Hanas
              thu thập và liên kết dữ liệu phân tán trong kiến trúc Lakehouse mở, có
              quản trị.
            </p>

            <div className={`${styles.trustRow} ${styles.animateIn} ${styles.delay4}`}>
              <span>Open formats</span>
              <span className={styles.trustDivider} aria-hidden="true">|</span>
              <span>On-premise</span>
              <span className={styles.trustDivider} aria-hidden="true">|</span>
              <span>Private cloud</span>
              <span className={styles.trustDivider} aria-hidden="true">|</span>
              <span>Hybrid</span>
            </div>
          </div>
        </div>

        <div className={`${styles.techRail} ${styles.animateIn} ${styles.delay5}`}>
          <span className={styles.techRailLabel}>XÂY TRÊN CÔNG NGHỆ MỞ</span>
          <div className={styles.techList}>
            {['Kafka', 'Spark', 'Iceberg', 'Airflow', 'DataHub', 'Dremio', 'vLLM'].map((tech) => (
              <span key={tech}>{tech}</span>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
