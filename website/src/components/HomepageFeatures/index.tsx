import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<'svg'>>;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Kiến Trúc Lakehouse Hiện Đại',
    Svg: require('@site/static/img/undraw_docusaurus_mountain.svg').default,
    description: (
      <>
        Kết hợp sức mạnh của Data Lake và Data Warehouse với Apache Iceberg,
        MinIO và Dremio cho khả năng lưu trữ và truy vấn dữ liệu linh hoạt.
      </>
    ),
  },
  {
    title: 'Xử Lý Dữ Liệu Toàn Diện',
    Svg: require('@site/static/img/undraw_docusaurus_tree.svg').default,
    description: (
      <>
        Tích hợp batch (NiFi) và streaming (Kafka) với orchestration từ Airflow
        và distributed computing từ Apache Spark.
      </>
    ),
  },
  {
    title: 'Quản Trị Dữ Liệu Tập Trung',
    Svg: require('@site/static/img/undraw_docusaurus_react.svg').default,
    description: (
      <>
        DataHub cho metadata management, Apache Ranger cho access control,
        và Vault cho secrets management trong một nền tảng thống nhất.
      </>
    ),
  },
];

function Feature({title, Svg, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
