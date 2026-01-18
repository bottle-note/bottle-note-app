# PR 생성

현재 브랜치의 변경사항을 분석하고 PR을 생성합니다.

## 작업 순서

1. **현재 상태 확인**
   - `git status`로 커밋되지 않은 변경사항 확인
   - `git log main..HEAD --oneline`으로 커밋 히스토리 확인
   - `git diff main...HEAD --stat`으로 변경된 파일 확인

2. **관련 이슈 검색** (bottle-note/workspace)
   - 브랜치명이나 커밋 메시지에서 키워드 추출
   - `gh issue list -R bottle-note/workspace --search "키워드" --limit 5`로 관련 이슈 검색
   - 관련 이슈가 있으면 사용자에게 선택하도록 제안

3. **PR 내용 작성**
   - 변경사항 요약 (한글)
   - 테스트 체크리스트
   - 관련 이슈 링크 (있는 경우)

4. **PR 생성**
   - `gh pr create` 명령어로 PR 생성
   - base 브랜치: main

## PR 본문 형식

```markdown
## 변경 사항
- [변경사항 요약]

## 테스트
- [ ] 로컬 테스트 완료
- [ ] iOS 빌드/실행 확인
- [ ] Android 빌드/실행 확인

## 관련 이슈
[이슈 링크 또는 "없음"]
```

커밋되지 않은 변경사항이 있으면 먼저 커밋할지 물어봐주세요.
