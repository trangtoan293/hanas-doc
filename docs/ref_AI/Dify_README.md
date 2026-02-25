Tôi sử dụng dify như là một AI workflow 
sử dụng context7 và websearch để search thêm thông tin về dify 
(https://github.com/langgenius/dify)

tôi dùng vLLM để host model LLM như là một inference chính 
các mô hình tôi dùng bao gồm LLM ví dụ như (   Qwen/Qwen3.5-397B-A17B, Qwen/Qwen3-Reranker-0.6B , Qwen/Qwen3-Embedding-0.6B )

https://huggingface.co/Qwen/Qwen3-Embedding-0.6B
https://huggingface.co/Qwen/Qwen3-Reranker-0.6B
https://huggingface.co/Qwen/Qwen3.5-397B-A17B

tôi dùng để phục vụ cho các use_case [Smart Office, Smart Documents Management, Next Best Offer, Real-time Identification of Potentially Risky Transactions]


Katalyst có phát triển riêng một service chuyên dùng để ocr các tài liệu nhằm tối ưu trong việc tìm kiếm, tra cứu tài liệu .

hỏi đáp tài liệu có liên quan 
tích hợp chung lại trong Dify 

Tôi sử dụng langfuse dùng để monitoring và đánh giá các kết quả của LLM trả về 
