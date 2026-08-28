import React, {useState} from 'react';
import styles from './styles.module.css';

interface FAQItem {
  question: string;
  answer: string;
}

const faqItems: FAQItem[] = [
  {
    question: 'Hanas có thể triển khai on-premise hoặc private cloud không?',
    answer: 'Có. Kiến trúc cloud-native của Hanas hỗ trợ triển khai trên hạ tầng riêng, private cloud hoặc mô hình hybrid, tùy theo yêu cầu bảo mật và vận hành của doanh nghiệp.',
  },
  {
    question: 'Nền tảng có tích hợp được với hệ thống dữ liệu hiện hữu?',
    answer: 'Hanas được thiết kế để kết nối với cơ sở dữ liệu, ứng dụng nghiệp vụ, message broker, object storage và công cụ BI hiện có thông qua connector, API và các chuẩn dữ liệu mở.',
  },
  {
    question: 'Doanh nghiệp có bị khóa vào một nhà cung cấp công nghệ không?',
    answer: 'Không. Hanas ưu tiên open-source, open table format và lớp giao tiếp tiêu chuẩn để doanh nghiệp có thể thay đổi compute, storage hoặc AI model mà không phải di chuyển toàn bộ dữ liệu.',
  },
  {
    question: 'Dữ liệu và ứng dụng AI được quản trị như thế nào?',
    answer: 'Metadata, lineage, policy truy cập, audit, secret management và observability được tích hợp xuyên suốt từ pipeline dữ liệu đến workflow AI và model inference.',
  },
  {
    question: 'Có thể sử dụng nhiều LLM hoặc tự host mô hình riêng không?',
    answer: 'Có. Hanas hỗ trợ kết nối model API bên ngoài và triển khai mô hình mã nguồn mở trên hạ tầng riêng thông qua vLLM, đồng thời theo dõi chất lượng và vận hành với Langfuse.',
  },
  {
    question: 'Nên bắt đầu triển khai Hanas từ đâu?',
    answer: 'Nên bắt đầu bằng một bài toán có giá trị rõ ràng, đánh giá nguồn dữ liệu và yêu cầu governance, sau đó triển khai theo pha để tạo kết quả sớm trước khi mở rộng toàn platform.',
  },
];

export default function FAQSection(): React.JSX.Element {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.layout}>
          <div className={styles.intro}>
            <span className={styles.eyebrow}>FAQ</span>
            <h2>Những câu hỏi thường gặp về Hanas.</h2>
            <p>
              Những câu doanh nghiệp hay hỏi khi cân nhắc đưa Hanas vào kiến trúc sẵn có.
            </p>
            <a href="/overview">
              Xem tài liệu tổng quan <span aria-hidden="true">↗</span>
            </a>
          </div>

          <div className={styles.accordion}>
            {faqItems.map((item, index) => {
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
