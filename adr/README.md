# ADR (Architecture Decision Records)

코드와 git 히스토리로 복원되지 않는 설계 결정을 기록한다. 계획과 진행 상태는 여기에 두지 않는다. 진행 추적은 workspace 이슈와 PR 본문이 맡는다. 결정이 없는 기능은 ADR을 만들지 않는다.

앱과 웹이 함께 지키는 약속은 웹 레포(`bottle-note-frontend/adr`)에 같은 주제의 ADR이 있어도 이 레포에 따로 남긴다. 이 레포의 ADR은 앱이 지켜야 할 쪽을 중심으로 쓴다.

## 작성 규칙

- 파일명: `YYYY.MM.DD 결정을 한 문장으로.md`. 날짜는 결정일이다.
- 제목 아래에 결정일, 대상(화면·브리지·플랫폼), 관련 이슈·PR을 적는다.
- 본문은 네 항목으로 쓴다.
  - `Context(배경)`: 결정이 필요한 문제와 제약
  - `Decision(결정)`: 선택한 방식과 지켜야 할 계약. 선택하지 않은 대안이 중요하면 `### Rejected Alternatives(선택하지 않은 대안)`로 남긴다.
  - `Status(상태)`: `Proposed(제안됨)`, `Accepted(승인됨)`, `Deprecated(폐기됨)`, `Superseded(대체됨)` 중 하나
  - `Consequences(결과와 영향)`: 비용, 제약, 이 결정을 지키는 테스트
- 결정이 바뀌면 기존 문서를 지우지 않고 상태를 `Superseded(대체됨)`로 바꾸고 새 문서를 가리킨다.

## 목록

| 결정일 | 문서 |
| ------ | ---- |
