import type {ReactNode} from 'react';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';

import HeroSection from '@site/src/components/HeroSection';
import PlatformGrid from '@site/src/components/PlatformGrid';
import TabNavigation from '@site/src/components/TabNavigation';
import CaseStudySection from '@site/src/components/CaseStudySection';
import CTABanner from '@site/src/components/CTABanner';
import ArchitectureSection from '@site/src/components/ArchitectureSection';
import TechStackSection from '@site/src/components/TechStackSection';

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title} - Nền tảng Dữ liệu Hợp nhất`}
      description="Hanas Data Platform - Data Lakehouse Platform với NiFi, Kafka, Spark, Airflow, Iceberg, MinIO, dbt, Dremio và DataHub">
      <main>
        <HeroSection />
        <PlatformGrid />
        <ArchitectureSection />
        <TabNavigation />
        <CaseStudySection />
        <TechStackSection />
        <CTABanner />
      </main>
    </Layout>
  );
}
