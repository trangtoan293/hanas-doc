import React from 'react';
import styles from './styles.module.css';

const barHeights = [38, 52, 46, 69, 62, 81, 74, 92, 84, 100, 94, 112];

export default function DashboardPanel(): React.JSX.Element {
  return (
    <div className={styles.dashboard} aria-hidden="true">
      <header className={styles.dashboardHeader}>
        <div className={styles.dashboardBrand}>
          <span className={styles.dashboardMark}>H</span>
          <span>
            <strong>Tổng quan điều hành</strong>
            <small>Hôm nay · Toàn doanh nghiệp</small>
          </span>
        </div>
        <div className={styles.dashboardStatus}>
          <span />
          Đã đồng bộ
        </div>
      </header>

      <div className={styles.kpiGrid}>
        <article className={styles.kpiCard} data-dashboard-item>
          <span>Doanh thu thuần</span>
          <strong>128,4 tỷ</strong>
          <small className={styles.positive}>↗ 18,6% so với kỳ trước</small>
        </article>
        <article className={styles.kpiCard} data-dashboard-item>
          <span>Giao dịch</span>
          <strong>2,48 triệu</strong>
          <small className={styles.positive}>↗ 7,2% so với kỳ trước</small>
        </article>
        <article className={styles.kpiCard} data-dashboard-item>
          <span>Khách hàng hoạt động</span>
          <strong>184.920</strong>
          <small className={styles.positive}>↗ 4,8% so với kỳ trước</small>
        </article>
      </div>

      <div className={styles.dashboardGrid}>
        <article className={styles.trendPanel} data-dashboard-item>
          <div className={styles.panelHeading}>
            <span>
              <small>Doanh thu</small>
              <strong>Xu hướng theo tháng</strong>
            </span>
            <span className={styles.panelDelta}>+24,8%</span>
          </div>
          <div className={styles.chartArea}>
            <div className={styles.chartGrid} />
            <svg viewBox="0 0 640 220" preserveAspectRatio="none" role="presentation">
              <defs>
                <linearGradient id="journeyChartFill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#69d4f5" stopOpacity="0.28" />
                  <stop offset="100%" stopColor="#69d4f5" stopOpacity="0" />
                </linearGradient>
              </defs>
              <path
                className={styles.chartFill}
                d="M0,190 C48,174 62,154 106,163 C148,172 171,118 218,132 C264,146 282,89 330,102 C382,116 401,70 448,82 C493,93 519,42 565,57 C596,67 616,45 640,31 L640,220 L0,220 Z"
              />
              <path
                className={styles.chartLine}
                d="M0,190 C48,174 62,154 106,163 C148,172 171,118 218,132 C264,146 282,89 330,102 C382,116 401,70 448,82 C493,93 519,42 565,57 C596,67 616,45 640,31"
                data-dashboard-path
              />
            </svg>
            <div className={styles.chartAxis}>
              <span>T1</span><span>T2</span><span>T3</span><span>T4</span><span>T5</span><span>T6</span>
            </div>
          </div>
        </article>

        <article className={styles.volumePanel} data-dashboard-item>
          <div className={styles.panelHeading}>
            <span>
              <small>Giao dịch</small>
              <strong>Giao dịch theo kênh</strong>
            </span>
            <span className={styles.livePill}>12 tháng</span>
          </div>
          <div className={styles.barChart}>
            {barHeights.map((height, index) => (
              <span
                data-dashboard-bar
                key={`${height}-${index}`}
                style={{'--bar-height': `${height}px`} as React.CSSProperties}
              />
            ))}
          </div>
          <div className={styles.qualityRow}>
            <span><i className={styles.qualityGood} /> Hợp lệ <strong>99,97%</strong></span>
            <span><i className={styles.qualityWarn} /> Ngoại lệ <strong>0,03%</strong></span>
          </div>
        </article>
      </div>

      <footer className={styles.dashboardFooter} data-dashboard-item>
        <span>Kỳ dữ liệu: Tháng này</span>
        <span>4 nguồn</span>
        <span>Cập nhật: 10:45</span>
        <strong>Xem chi tiết →</strong>
      </footer>
    </div>
  );
}
