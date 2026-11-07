import React, {useState} from 'react';
import Link from '@docusaurus/Link';
import useLandingCopy from '@site/src/components/landingCopy';
import styles from './styles.module.css';

export default function FAQSection(): React.JSX.Element {
  const {faq} = useLandingCopy();
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.layout}>
          <div className={styles.intro}>
            <h2>
              {faq.titleLines[0]}
              <br className="landingDesktopBreak" />{' '}
              {faq.titleLines[1]}
            </h2>
            <Link to="/docs/get-started/introduction">
              {faq.link} <span aria-hidden="true">↗</span>
            </Link>
          </div>

          <div className={styles.accordion}>
            {faq.items.map((item, index) => {
              const isOpen = openIndex === index;
              const panelId = `faq-panel-${index}`;
              const buttonId = `faq-button-${index}`;

              return (
                <article key={item.question} className={styles.item}>
                  <h3>
                    <button
                      id={buttonId}
                      type="button"
                      aria-expanded={isOpen}
                      aria-controls={panelId}
                      onClick={() => setOpenIndex(isOpen ? null : index)}
                    >
                      <span>{item.question}</span>
                      <i className={isOpen ? styles.open : ''} aria-hidden="true" />
                    </button>
                  </h3>
                  <div
                    id={panelId}
                    role="region"
                    aria-labelledby={buttonId}
                    className={styles.answer}
                    hidden={!isOpen}
                  >
                    <p>{item.answer}</p>
                  </div>
                </article>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
