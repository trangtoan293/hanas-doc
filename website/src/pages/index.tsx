import type {ReactNode} from 'react';
import Layout from '@theme/Layout';

import HeroSection from '@site/src/components/HeroSection';
import PlatformGrid from '@site/src/components/PlatformGrid';
import TabNavigation from '@site/src/components/TabNavigation';
import CaseStudySection from '@site/src/components/CaseStudySection';
import UseCasesSection from '@site/src/components/UseCasesSection';
import FAQSection from '@site/src/components/FAQSection';
import CTABanner from '@site/src/components/CTABanner';
import styles from './index.module.css';

export default function Home(): ReactNode {
  return (
    <Layout
      title="Nền tảng Data & AI cho doanh nghiệp"
      description="Hanas là nền tảng Data & AI hợp nhất giúp doanh nghiệp xây dựng lakehouse, quản trị dữ liệu và đưa AI vào vận hành trên một kiến trúc mở.">
      <main className={styles.landingPage}>
        <HeroSection />
        <PlatformGrid />
        <TabNavigation />
        <CaseStudySection />
        <UseCasesSection />
        <FAQSection />
        <CTABanner />
      </main>
    </Layout>
  );
}
