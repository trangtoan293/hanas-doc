import type {ReactNode} from 'react';
import Layout from '@theme/Layout';
import Head from '@docusaurus/Head';
import {HtmlClassNameProvider} from '@docusaurus/theme-common';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';

import HeroSection from '@site/src/components/HeroSection';
import DataJourneySection from '@site/src/components/DataJourneySection';
import PlatformGrid from '@site/src/components/PlatformGrid';
import TabNavigation from '@site/src/components/TabNavigation';
import UseCasesSection from '@site/src/components/UseCasesSection';
import FAQSection from '@site/src/components/FAQSection';
import CTABanner from '@site/src/components/CTABanner';
import useLandingCopy from '@site/src/components/landingCopy';
import styles from './index.module.css';

export default function Home(): ReactNode {
  const {siteConfig, i18n} = useDocusaurusContext();
  const {meta, faq} = useLandingCopy();
  // 1200x630 share cards rendered from the hero, one per locale.
  const shareImage = `${siteConfig.url}/img/og-hanas-${i18n.currentLocale === 'en' ? 'en' : 'vi'}.jpg`;
  const structuredData = [
    {
      '@context': 'https://schema.org',
      '@type': 'SoftwareApplication',
      name: 'Hanas Data Platform',
      applicationCategory: 'BusinessApplication',
      operatingSystem: 'Kubernetes',
      inLanguage: i18n.currentLocale,
      description: meta.schemaDescription,
      publisher: {'@type': 'Organization', name: 'Katalyst'},
    },
    {
      '@context': 'https://schema.org',
      '@type': 'FAQPage',
      mainEntity: faq.items.map((item) => ({
        '@type': 'Question',
        name: item.question,
        acceptedAnswer: {'@type': 'Answer', text: item.answer},
      })),
    },
  ];

  return (
    <HtmlClassNameProvider className="landing-page">
      <Layout title={meta.title} description={meta.description}>
        <Head>
          <meta name="keywords" content={meta.keywords} />
          <meta property="og:image" content={shareImage} />
          <meta name="twitter:image" content={shareImage} />
          <script type="application/ld+json">{JSON.stringify(structuredData)}</script>
        </Head>
        <main className={styles.landingPage}>
          <HeroSection />
          <DataJourneySection />
          <PlatformGrid />
          <TabNavigation />
          <UseCasesSection />
          <FAQSection />
          <CTABanner />
        </main>
      </Layout>
    </HtmlClassNameProvider>
  );
}
