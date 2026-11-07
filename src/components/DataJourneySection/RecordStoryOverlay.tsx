import React from 'react';
import {gatewayRecords} from './journeyRecords';
import {AgentPanel, OntologyMap} from './OntologyAgent';
import type {LandingCopy} from '@site/src/components/landingCopy';
import styles from './styles.module.css';

interface RecordStoryOverlayProps {
  activeStage: number;
  copy: LandingCopy;
}

export default function RecordStoryOverlay({activeStage, copy}: RecordStoryOverlayProps): React.JSX.Element {
  return (
    <div className={styles.recordStory} aria-hidden="true">
      <div className={`${styles.gatewayRecordLayer} ${activeStage === 1 ? styles.recordLayerActive : ''}`}>
        <header className={styles.gatewayHeader}>
          <span className={styles.gatewayMark}>H</span>
          <span className={styles.gatewayIdentity}>
            <strong>{copy.gateway.name}</strong>
            <small>{copy.gateway.mode}</small>
          </span>
          <span className={styles.gatewayStatus}>{copy.gateway.status}</span>
        </header>
        <div className={styles.gatewayRecordStack}>
          {gatewayRecords.map((record) => (
            <div className={styles.gatewayRecord} key={record.id}>
              <span>{record.source}</span>
              <code>{record.id}</code>
              <small>{record.event}</small>
            </div>
          ))}
        </div>
        <footer className={styles.gatewayFooter}>
          <span><i /> {copy.gateway.footer}</span>
        </footer>
      </div>

      <div className={`${styles.qualityRecordLayer} ${activeStage === 2 ? `${styles.recordLayerActive} journey-layer-active` : ''}`}>
        <OntologyMap copy={copy.ontology} />
      </div>

      <div className={`${styles.vaultDiagramLayer} ${activeStage === 3 ? `${styles.recordLayerActive} journey-layer-active` : ''}`}>
        <AgentPanel copy={copy.agent} />
      </div>
    </div>
  );
}

export function MobileRecordEvidence({stage, copy}: {stage: number; copy: LandingCopy}): React.JSX.Element | null {
  if (stage === 2) {
    return (
      <div className="journey-layer-active" aria-label={copy.sample.ontologyAria}>
        <OntologyMap mobile copy={copy.ontology} />
      </div>
    );
  }

  if (stage === 3) {
    return (
      <div className="journey-layer-active" aria-label={copy.sample.agentAria}>
        <AgentPanel mobile copy={copy.agent} />
      </div>
    );
  }

  const records = copy.sample.rows[stage];
  if (!records) return null;

  return (
    <div className={styles.mobileRecordEvidence} aria-label={copy.sample.label}>
      <span>{copy.sample.label}</span>
      {records.map((record) => (
        <div key={record.id}>
          <code>{record.id}</code>
          <small>{record.value}</small>
        </div>
      ))}
    </div>
  );
}
