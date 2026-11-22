// 코드 복사 버튼(테마 기본 기능)에 스크린 리더용 이름을 붙인다.
(function () {
  function label(button) {
    if (!button.hasAttribute("aria-label")) {
      button.setAttribute("aria-label", button.title || "클립보드로 복사");
    }
  }

  function labelAll() {
    document
      .querySelectorAll("button[data-md-type='copy']")
      .forEach(label);
  }

  labelAll();

  // 버튼은 테마 스크립트가 실행 시점에 생성하므로 새로 추가된 노드도 확인한다.
  if (typeof MutationObserver !== "undefined") {
    new MutationObserver(function (records) {
      records.forEach(function (record) {
        record.addedNodes.forEach(function (node) {
          if (node.nodeType !== 1) return;
          if (node.matches("button[data-md-type='copy']")) label(node);
          node
            .querySelectorAll("button[data-md-type='copy']")
            .forEach(label);
        });
      });
    }).observe(document.documentElement, { childList: true, subtree: true });
  }
})();
