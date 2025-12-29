// Production 애플리케이션의 Prod/Dev URL 매핑
const productionApps = {
  'Joossam': {
    prod: 'https://joossameng.com',
    dev: 'https://dev.joossameng.com'
  },
  'Jaejadle': {
    prod: 'https://jaejadle.kro.kr',
    dev: 'https://dev.jaejadle.kro.kr'
  },
  'Jotion': {
    prod: 'https://jotion.kro.kr',
    dev: 'https://dev.jotion.kro.kr'
  },
  'Portfolio': {
    prod: 'https://minjo0213.kro.kr',
    dev: 'https://dev.minjo0213.kro.kr'
  },
  'Todo': {
    prod: 'https://todo0213.kro.kr',
    dev: 'https://dev.todo0213.kro.kr'
  },
  'Jovies': {
    prod: 'https://jovies.kro.kr',
    dev: 'https://dev.jovies.kro.kr'
  }
};

// Production 카드에 Prod/Dev 버튼 추가
function addProdDevButtons() {
  // Production 섹션의 모든 카드 찾기
  const productionSection = document.querySelector('[data-group="Production"]') || 
                            Array.from(document.querySelectorAll('.group-title'))
                            .find(el => el.textContent.trim() === 'Production')?.closest('.column');
  
  if (!productionSection) {
    // 다른 방법으로 Production 섹션 찾기
    const allCards = document.querySelectorAll('.card');
    allCards.forEach(card => {
      const titleElement = card.querySelector('.title');
      if (titleElement && productionApps[titleElement.textContent.trim()]) {
        addButtonsToCard(card, titleElement.textContent.trim());
      }
    });
    return;
  }

  // Production 섹션 내의 모든 카드 찾기
  const cards = productionSection.querySelectorAll('.card');
  cards.forEach(card => {
    const titleElement = card.querySelector('.title');
    if (titleElement) {
      const appName = titleElement.textContent.trim();
      if (productionApps[appName]) {
        addButtonsToCard(card, appName);
      }
    }
  });
}

// 카드에 Prod/Dev 버튼 추가
function addButtonsToCard(card, appName) {
  // 이미 버튼이 추가되었는지 확인
  if (card.querySelector('.prod-dev-buttons')) {
    return;
  }

  const appUrls = productionApps[appName];
  if (!appUrls) return;

  // 기존 링크 제거 또는 비활성화
  const existingLink = card.querySelector('a[href]');
  if (existingLink) {
    existingLink.style.pointerEvents = 'none';
    existingLink.style.cursor = 'default';
  }

  // 버튼 컨테이너 생성
  const buttonContainer = document.createElement('div');
  buttonContainer.className = 'prod-dev-buttons';
  
  // Prod 버튼
  const prodButton = document.createElement('a');
  prodButton.href = appUrls.prod;
  prodButton.target = '_blank';
  prodButton.className = 'env-button prod-button';
  prodButton.innerHTML = '<i class="fas fa-rocket"></i> Prod';
  prodButton.title = 'Production Environment';
  
  // Dev 버튼
  const devButton = document.createElement('a');
  devButton.href = appUrls.dev;
  devButton.target = '_blank';
  devButton.className = 'env-button dev-button';
  devButton.innerHTML = '<i class="fas fa-code-branch"></i> Dev';
  devButton.title = 'Development Environment';
  
  buttonContainer.appendChild(prodButton);
  buttonContainer.appendChild(devButton);
  
  // 카드의 content 영역에 버튼 추가
  const cardContent = card.querySelector('.card-content') || card;
  cardContent.appendChild(buttonContainer);
}

// DOM이 로드된 후 실행
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    // 약간의 지연을 두고 실행 (Homer가 카드를 렌더링할 시간 필요)
    setTimeout(addProdDevButtons, 500);
    // MutationObserver로 동적 콘텐츠 감지
    observeChanges();
  });
} else {
  setTimeout(addProdDevButtons, 500);
  observeChanges();
}

// DOM 변경 감지하여 동적으로 추가된 카드에도 버튼 추가
function observeChanges() {
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.addedNodes.length) {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === 1) { // Element node
            if (node.classList && node.classList.contains('card')) {
              const titleElement = node.querySelector('.title');
              if (titleElement && productionApps[titleElement.textContent.trim()]) {
                addButtonsToCard(node, titleElement.textContent.trim());
              }
            }
            // 자식 노드에서도 카드 찾기
            const cards = node.querySelectorAll && node.querySelectorAll('.card');
            if (cards) {
              cards.forEach(card => {
                const titleElement = card.querySelector('.title');
                if (titleElement && productionApps[titleElement.textContent.trim()]) {
                  addButtonsToCard(card, titleElement.textContent.trim());
                }
              });
            }
          }
        });
      }
    });
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true
  });
}

