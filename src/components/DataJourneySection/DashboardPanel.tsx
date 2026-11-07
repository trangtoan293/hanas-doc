import React from 'react';
import type {LandingCopy} from '@site/src/components/landingCopy';
import styles from './styles.module.css';

const barHeights = [38, 52, 46, 69, 62, 81, 74, 92, 84, 100, 94, 112];

export default function DashboardPanel({copy}: {copy: LandingCopy['dashboard']}): React.JSX.Element {
  return (
    <div className={styles.dashboard} aria-hidden="true">
      <header className={styles.dashboardHeader}>
        <div className={styles.dashboardBrand}>
          <span className={styles.dashboardMark}>H</span>
          <span>
            <strong>{copy.title}</strong>
            <small>{copy.scope}</small>
          </span>
        </div>
        <div className={styles.dashboardStatus}>
          <span />
          {copy.synced}
        </div>
      </header>

      <div className={styles.kpiGrid}>
        {copy.kpis.map((kpi) => (
          <article className={styles.kpiCard} data-dashboard-item key={kpi.label}>
            <span>{kpi.label}</span>
            <strong>{kpi.value}</strong>
            <small className={styles.positive}>{kpi.delta}</small>
          </article>
        ))}
      </div>

      <div className={styles.dashboardGrid}>
        <article className={styles.trendPanel} data-dashboard-item>
          <div className={styles.panelHeading}>
            <span>
              <small>{copy.trendKicker}</small>
              <strong>{copy.trendTitle}</strong>
            </span>
            <span className={styles.panelDelta}>{copy.trendDelta}</span>
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
                // Normalised length so the draw-on tween ends exactly at the line's end.
                pathLength={1}
              />
            </svg>
            <div className={styles.chartAxis}>
              {copy.months.map((month) => <span key={month}>{month}</span>)}
            </div>
          </div>
        </article>

        <article className={styles.volumePanel} data-dashboard-item>
          <div className={styles.panelHeading}>
            <span>
              <small>{copy.volumeKicker}</small>
              <strong>{copy.volumeTitle}</strong>
            </span>
            <span className={styles.livePill}>{copy.volumePill}</span>
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
            <span><i className={styles.qualityGood} /> {copy.valid} <strong>{copy.validValue}</strong></span>
            <span><i className={styles.qualityWarn} /> {copy.exceptions} <strong>{copy.exceptionsValue}</strong></span>
          </div>
        </article>
      </div>

      <footer className={styles.dashboardFooter} data-dashboard-item>
        {copy.footer.map((item) => <span key={item}>{item}</span>)}
        <strong>{copy.details}</strong>
      </footer>
    </div>
  );
}
