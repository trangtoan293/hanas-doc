import React from 'react';
import type {LandingCopy} from '@site/src/components/landingCopy';
import styles from './ontologyAgent.module.css';

// Illustrative content for chapters 03 (Ontology) and 04 (AI Agent). Labeled "Dữ liệu minh họa" on screen.

const OBJECT_IDS = ['customer', 'account', 'branch', 'transaction'];
// Edge labels sit between the 2x2 cards: top, right, bottom, left.
const EDGE_IDS = ['top', 'right', 'bottom', 'left'];

export function OntologyMap({mobile = false, copy}: {mobile?: boolean; copy: LandingCopy['ontology']}): React.JSX.Element {
  return (
    <div className={`${styles.panel} ${styles.ontology} ${mobile ? styles.mobile : ''}`}>
      <header className={styles.header}>
        <span className={styles.mark}>O</span>
        <span className={styles.identity}>
          <strong>Ontology</strong>
          <small>{copy.subtitle}</small>
        </span>
        <span className={styles.badge}>{copy.badge}</span>
      </header>

      <div className={styles.graph}>
        <svg className={styles.edges} viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
          {/* Centers of the 2x2 cards; the lines run under the cards and show in the gaps. */}
          <line x1="25" y1="30" x2="75" y2="30" />
          <line x1="75" y1="30" x2="75" y2="70" />
          <line x1="75" y1="70" x2="25" y2="70" />
          <line x1="25" y1="70" x2="25" y2="30" />
          <line x1="25" y1="30" x2="75" y2="70" />
        </svg>
        {copy.objects.map((type, index) => (
          <div className={styles.node} key={OBJECT_IDS[index]} data-node={OBJECT_IDS[index]}>
            <strong>{type.name}</strong>
            {type.properties.map((property) => (
              <code key={property}>{property}</code>
            ))}
          </div>
        ))}
        {copy.links.map((label, index) => (
          <span className={styles.edgeLabel} key={EDGE_IDS[index]} data-edge={EDGE_IDS[index]}>
            {label}
          </span>
        ))}
        <div className={styles.metricHub}>
          <small>Metric</small>
          {copy.metrics.map((metric) => (
            <strong key={metric}>{metric}</strong>
          ))}
        </div>
      </div>

      <footer className={styles.footer}>
        <span><i /> {copy.bound}</span>
        <code>iceberg.mart.giao_dich</code>
      </footer>
    </div>
  );
}

export function AgentPanel({mobile = false, copy}: {mobile?: boolean; copy: LandingCopy['agent']}): React.JSX.Element {
  return (
    <div className={`${styles.panel} ${styles.agent} ${mobile ? styles.mobile : ''}`}>
      <header className={styles.header}>
        <span className={styles.mark}>K</span>
        <span className={styles.identity}>
          <strong>Kapas</strong>
          <small>{copy.subtitle}</small>
        </span>
        <span className={styles.badge}>{copy.badge}</span>
      </header>

      <div className={styles.thread}>
        <p className={styles.question}>{copy.question}</p>

        <ol className={styles.steps}>
          {copy.steps.map((step) => (
            <li key={step.label}>
              <i aria-hidden="true" />
              <span>{step.label}</span>
              <code>{step.detail}</code>
            </li>
          ))}
        </ol>

        <div className={styles.answer}>
          <p>
            {copy.answer.before}
            <strong>{copy.answer.value}</strong>
            {copy.answer.middle}
            <strong>{copy.answer.change}</strong>
            {copy.answer.after}
          </p>
          <div className={styles.bars} aria-hidden="true">
            {[38, 56, 47, 68, 80, 100].map((height, index) => (
              <span key={index} style={{'--bar': `${height}%`} as React.CSSProperties} />
            ))}
          </div>
          <small>{copy.source}</small>
        </div>
      </div>
    </div>
  );
}
