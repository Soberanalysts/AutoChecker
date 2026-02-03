# 이미지 OCR 테스트 스크립트 (Windows PowerShell)

$IMAGE_FILE = "C:\Users\YourUsername\AutoChecker\example\쓰기 채점_예문 (1).jpg"
$N8N_URL = "http://localhost:5678"

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "이미지 OCR 테스트" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# 이미지 파일 존재 확인
if (-not (Test-Path $IMAGE_FILE)) {
    Write-Host "❌ 이미지 파일을 찾을 수 없습니다: $IMAGE_FILE" -ForegroundColor Red
    Write-Host "위 경로를 사용자의 실제 경로로 수정하세요." -ForegroundColor Yellow
    exit 1
}

Write-Host "이미지 파일: $IMAGE_FILE"
Write-Host "Endpoint: $N8N_URL/webhook/image-ocr"
Write-Host ""
Write-Host "텍스트 추출 중..." -ForegroundColor Yellow
Write-Host ""

# HTTP Request 기반 OCR 테스트
try {
    curl.exe -X POST "$N8N_URL/webhook/image-ocr" `
      -F "data=@$IMAGE_FILE" `
      -H "Content-Type: multipart/form-data" `
      -o output_image_ocr.json

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 성공! 결과가 output_image_ocr.json에 저장되었습니다." -ForegroundColor Green
        Write-Host ""
        Write-Host "--- 추출된 텍스트 미리보기 ---" -ForegroundColor Cyan

        $result = Get-Content output_image_ocr.json | ConvertFrom-Json
        $extractedText = $result.extracted_text
        $lines = $extractedText -split "`n"
        $preview = $lines | Select-Object -First 30
        $preview | ForEach-Object { Write-Host $_ }

        Write-Host ""
        Write-Host "--- 메타데이터 ---" -ForegroundColor Cyan
        Write-Host "문자 수: $($result.metadata.char_count)"
        Write-Host "단어 수: $($result.metadata.word_count)"
        Write-Host "줄 수: $($result.metadata.line_count)"
        Write-Host "추출 시간: $($result.metadata.extracted_at)"
        Write-Host "사용 모델: $($result.metadata.model)"
        Write-Host ""
    } else {
        Write-Host "❌ 실패! n8n이 실행 중인지, 워크플로우가 활성화되어 있는지 확인하세요." -ForegroundColor Red
        Write-Host ""
    }
} catch {
    Write-Host "❌ 오류 발생: $_" -ForegroundColor Red
}

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "테스트 완료!" -ForegroundColor Cyan
Write-Host "전체 결과는 output_image_ocr.json에서 확인하세요." -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan