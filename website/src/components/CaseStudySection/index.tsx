import React from 'react';
import styles from './styles.module.css';

export default function CaseStudySection(): React.JSX.Element {
  return (
    <section className={styles.caseStudySection}>
      <div className="container">
        <div className={styles.content}>
          <div className={styles.stats}>
            <div className={styles.statItem}>
              <div className={styles.statValue}>50%</div>
              <div className={styles.statLabel}>Hiệu suất tăng</div>
            </div>
            <div className={styles.statItem}>
              <div className={styles.statValue}>70%</div>
              <div className={styles.statLabel}>Chi phí giảm</div>
            </div>
            <div className={styles.statItem}>
              <div className={styles.statValue}>99.9%</div>
              <div className={styles.statLabel}>Uptime</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
