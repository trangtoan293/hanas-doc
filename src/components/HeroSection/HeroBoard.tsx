import React from 'react';
import type {LandingCopy} from '@site/src/components/landingCopy';
import styles from './board.module.css';

type BoardCopy = LandingCopy['hero']['board'];

interface EdgeCard {
  name: string;
  meta: string;
  items: string;
}

function EdgeColumn({title, cards, side}: {title: string; cards: EdgeCard[]; side: 'in' | 'out'}): React.JSX.Element {
  return (
    <div className={side === 'in' ? styles.sources : styles.consumers}>
      <span className={styles.colTitle}>{title}</span>
      {cards.map((card, index) => (
        <div
          key={card.name}
          className={`${styles.edgeCard} ${side === 'out' && index === 0 ? styles.aiCard : ''}`}
          style={{'--i': index} as React.CSSProperties}
        >
          <strong>{card.name}</strong>
          <span className={styles.meta}>{card.meta}</span>
          <span className={styles.items}>{card.items}</span>
        </div>
      ))}
    </div>
  );
}

export default function HeroBoard({copy}: {copy: BoardCopy}): React.JSX.Element {
  return (
    <figure className={styles.board} aria-label={copy.aria}>
      <EdgeColumn title={copy.sourcesTitle} cards={copy.sources} side="in" />

      <div className={styles.platform}>
        <div className={styles.platformHead}>
          <span className={styles.platformName}>{copy.platform}</span>
          <span className={styles.platformMeta}>{copy.platformMeta}</span>
        </div>

        <div className={styles.govern}>
          <span className={styles.bandTitle}>{copy.governTitle}</span>
          <div className={styles.governItems}>
            {copy.govern.map((item) => (
              <div key={item.name} className={styles.chipCard}>
                <strong>{item.name}</strong>
                <span>{item.detail}</span>
              </div>
            ))}
          </div>
        </div>

        <div className={styles.planes}>
          <div className={styles.process}>
            <span className={styles.bandTitle}>{copy.processTitle}</span>
            {copy.process.map((item) => (
              <div key={item.name} className={styles.processItem}>
                <strong>{item.name}</strong>
                <span>{item.detail}</span>
              </div>
            ))}
          </div>

          <div className={styles.core}>
            <div className={styles.engine}>
              <strong>{copy.coreTitle}</strong>
              <span>{copy.coreMeta}</span>
            </div>
            <div className={styles.lake}>
              <strong>{copy.lakeTitle}</strong>
              <div className={styles.zones}>
                {copy.zones.map((zone) => (
                  <div key={zone.name} className={styles.zone}>
                    <b>{zone.name}</b>
                    <span>{zone.detail}</span>
                  </div>
                ))}
              </div>
              <div className={styles.features}>
                {copy.features.map((feature) => (
                  <span key={feature}>{feature}</span>
                ))}
              </div>
            </div>
            <div className={styles.storage}>{copy.storage}</div>
          </div>

          <div className={styles.semantic}>
            <span className={styles.bandTitle}>{copy.semanticTitle}</span>
            <div className={styles.ontology}>
              <strong>{copy.ontology.name}</strong>
              <span>{copy.ontology.detail}</span>
              <div className={styles.graph} aria-hidden="true">
                {copy.ontologyItems.map((item) => (
                  <i key={item}>{item}</i>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      <EdgeColumn title={copy.consumersTitle} cards={copy.consumers} side="out" />
    </figure>
  );
}
