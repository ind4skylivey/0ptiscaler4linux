// Main Application Logic
document.addEventListener('DOMContentLoaded', () => {
    initNavigation();
    initTypingEffect();
    initTabs();
    initClipboard();
});

// Navigation Logic
function initNavigation() {
    const navbar = document.querySelector('.navbar');
    const mobileBtn = document.getElementById('mobile-menu-btn');
    const navLinks = document.querySelector('.nav-links');

    // Scroll Effect
    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    });

    // Mobile Menu
    if (mobileBtn) {
        mobileBtn.addEventListener('click', () => {
            navLinks.classList.toggle('active');
            mobileBtn.classList.toggle('active');

            // Animate hamburger to X
            const spans = mobileBtn.querySelectorAll('span');
            if (mobileBtn.classList.contains('active')) {
                spans[0].style.transform = 'rotate(45deg) translate(5px, 5px)';
                spans[1].style.opacity = '0';
                spans[2].style.transform = 'rotate(-45deg) translate(5px, -5px)';
            } else {
                spans[0].style.transform = 'none';
                spans[1].style.opacity = '1';
                spans[2].style.transform = 'none';
            }
        });
    }

    // Smooth Scroll for Anchors
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                // Close mobile menu if open
                if (navLinks.classList.contains('active')) {
                    navLinks.classList.remove('active');
                    mobileBtn.classList.remove('active');
                    const spans = mobileBtn.querySelectorAll('span');
                    spans[0].style.transform = 'none';
                    spans[1].style.opacity = '1';
                    spans[2].style.transform = 'none';
                }

                window.scrollTo({
                    top: target.offsetTop - 80,
                    behavior: 'smooth'
                });
            }
        });
    });
}

// Typing Effect
function initTypingEffect() {
    const element = document.getElementById('typing-text');
    if (!element) return;

    const words = ['FSR 4', 'XeSS', 'DLSS', 'Performance'];
    let wordIndex = 0;
    let charIndex = 0;
    let isDeleting = false;
    let typeSpeed = 100;

    function type() {
        const currentWord = words[wordIndex];

        if (isDeleting) {
            element.textContent = currentWord.substring(0, charIndex - 1);
            charIndex--;
            typeSpeed = 50;
        } else {
            element.textContent = currentWord.substring(0, charIndex + 1);
            charIndex++;
            typeSpeed = 150;
        }

        if (!isDeleting && charIndex === currentWord.length) {
            isDeleting = true;
            typeSpeed = 2000; // Pause at end
        } else if (isDeleting && charIndex === 0) {
            isDeleting = false;
            wordIndex = (wordIndex + 1) % words.length;
            typeSpeed = 500; // Pause before new word
        }

        setTimeout(type, typeSpeed);
    }

    type();
}

// Installation Tabs
function initTabs() {
    const tabs = document.querySelectorAll('.install-tab');
    const panels = document.querySelectorAll('.install-panel');

    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            // Remove active class from all
            tabs.forEach(t => t.classList.remove('active'));
            panels.forEach(p => p.classList.remove('active'));

            // Add active class to clicked
            tab.classList.add('active');

            // Show corresponding panel
            const targetId = `panel-${tab.dataset.tab}`;
            document.getElementById(targetId).classList.add('active');
        });
    });
}

// Clipboard Functionality
function initClipboard() {
    const copyBtns = document.querySelectorAll('.copy-btn');

    copyBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const textToCopy = btn.dataset.copy;

            navigator.clipboard.writeText(textToCopy).then(() => {
                // Visual feedback
                const originalContent = btn.innerHTML;
                btn.innerHTML = `
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                    Copied!
                `;
                btn.style.borderColor = 'var(--primary)';
                btn.style.color = 'var(--primary)';

                setTimeout(() => {
                    btn.innerHTML = originalContent;
                    btn.style.borderColor = '';
                    btn.style.color = '';
                }, 2000);
            });
        });
    });
}

// Comparison Slider Logic
document.addEventListener('DOMContentLoaded', () => {
    const slider = document.getElementById('comp-slider');
    const overlay = document.getElementById('comp-overlay');
    const container = document.querySelector('.comparison-wrapper');

    if (slider && overlay && container) {
        let isDragging = false;

        // Mouse Events
        slider.addEventListener('mousedown', () => isDragging = true);
        document.addEventListener('mouseup', () => isDragging = false);
        document.addEventListener('mousemove', (e) => {
            if (!isDragging) return;
            moveSlider(e.clientX);
        });

        // Touch Events
        slider.addEventListener('touchstart', () => isDragging = true);
        document.addEventListener('touchend', () => isDragging = false);
        document.addEventListener('touchmove', (e) => {
            if (!isDragging) return;
            moveSlider(e.touches[0].clientX);
        });

        function moveSlider(clientX) {
            const rect = container.getBoundingClientRect();
            let x = clientX - rect.left;

            // Clamp values
            if (x < 0) x = 0;
            if (x > rect.width) x = rect.width;

            const percentage = (x / rect.width) * 100;

            slider.style.left = `${percentage}%`;
            overlay.style.width = `${percentage}%`;
        }
    }
});

// Konami Code Easter Egg - Overclock Mode
const konamiCode = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'b', 'a'];
let konamiIndex = 0;

document.addEventListener('keydown', (e) => {
    if (e.key === konamiCode[konamiIndex]) {
        konamiIndex++;
        if (konamiIndex === konamiCode.length) {
            activateOverclockMode();
            konamiIndex = 0;
        }
    } else {
        konamiIndex = 0;
    }
});

function activateOverclockMode() {
    // Visual feedback
    const body = document.body;
    body.style.transition = 'filter 0.5s ease';
    body.style.filter = 'hue-rotate(90deg) contrast(1.2)';

    // Add overclock badge
    const badge = document.createElement('div');
    badge.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #ff0000;
        color: white;
        padding: 10px 20px;
        font-family: 'Orbitron', sans-serif;
        font-weight: bold;
        z-index: 9999;
        border: 2px solid white;
        box-shadow: 0 0 20px #ff0000;
        animation: pulse 0.5s infinite;
        text-transform: uppercase;
    `;
    badge.textContent = '⚠️ OVERCLOCK MODE ACTIVATED ⚠️';
    document.body.appendChild(badge);

    // Speed up animations
    document.documentElement.style.setProperty('--transition-normal', '50ms');

    // Matrix rain speed up
    if (window.matrixInterval) clearInterval(window.matrixInterval);

    // Shake effect
    body.style.animation = 'shake 0.5s cubic-bezier(.36,.07,.19,.97) both';

    setTimeout(() => {
        body.style.animation = '';
        alert('🚀 SYSTEM OPTIMIZED TO 1000% PERFORMANCE!');
    }, 500);
}

// Add shake keyframe dynamically
const styleSheet = document.createElement("style");
styleSheet.innerText = `
    @keyframes shake {
        10%, 90% { transform: translate3d(-1px, 0, 0); }
        20%, 80% { transform: translate3d(2px, 0, 0); }
        30%, 50%, 70% { transform: translate3d(-4px, 0, 0); }
        40%, 60% { transform: translate3d(4px, 0, 0); }
    }
`;
document.head.appendChild(styleSheet);
