// Visual Effects - Particles, Terminal Animation, Counters
class ParticleSystem {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        if (!this.container) return;

        this.particleCount = 50;
        this.init();
    }

    init() {
        for (let i = 0; i < this.particleCount; i++) {
            this.createParticle(i);
        }
    }

    createParticle(index) {
        const particle = document.createElement('div');
        particle.className = 'particle';

        const size = Math.random() * 4 + 2;
        const left = Math.random() * 100;
        const delay = Math.random() * 8;
        const duration = Math.random() * 4 + 6;

        particle.style.cssText = `
            width: ${size}px;
            height: ${size}px;
            left: ${left}%;
            animation-delay: ${delay}s;
            animation-duration: ${duration}s;
            background: ${Math.random() > 0.5 ? '#00ff88' : '#00ccff'};
        `;

        this.container.appendChild(particle);
    }
}

// Terminal Animation
class TerminalAnimation {
    constructor(outputId) {
        this.output = document.getElementById(outputId);
        if (!this.output) return;

        this.commands = [
            { type: 'prompt', text: '$ ', delay: 0 },
            { type: 'command', text: 'optiscaler-install', delay: 50 },
            { type: 'output', text: '\n🔍 Detecting GPU...', delay: 800 },
            { type: 'info', text: '\n   → AMD Radeon RX 7900 XTX (RDNA3)', delay: 1200 },
            { type: 'output', text: '\n📂 Scanning Steam library...', delay: 1600 },
            { type: 'success', text: '\n   ✓ Found 12 compatible games', delay: 2000 },
            { type: 'output', text: '\n⚙️  Generating configurations...', delay: 2400 },
            { type: 'success', text: '\n   ✓ OptiScaler.ini created', delay: 2800 },
            { type: 'success', text: '\n   ✓ fakenvapi.ini created', delay: 3000 },
            { type: 'output', text: '\n🚀 Installing to Cyberpunk 2077...', delay: 3400 },
            { type: 'success', text: '\n   ✓ Installation complete!', delay: 3800 },
            { type: 'output', text: '\n\n📊 Expected Performance:', delay: 4200 },
            { type: 'info', text: '\n   → FSR4: +60-80% FPS', delay: 4400 },
            { type: 'info', text: '\n   → Anti-Lag 2: -30ms latency', delay: 4600 },
            { type: 'success', text: '\n\n✨ Ready to game!', delay: 5000 }
        ];

        this.currentIndex = 0;
        this.init();
    }

    init() {
        this.animate();
        // Loop animation
        setInterval(() => {
            this.output.innerHTML = '';
            this.currentIndex = 0;
            this.animate();
        }, 12000);
    }

    animate() {
        if (this.currentIndex >= this.commands.length) return;

        const cmd = this.commands[this.currentIndex];

        setTimeout(() => {
            this.addLine(cmd.type, cmd.text);
            this.currentIndex++;
            this.animate();
        }, cmd.delay);
    }

    addLine(type, text) {
        const span = document.createElement('span');
        span.className = type;
        span.textContent = text;
        this.output.appendChild(span);
        this.output.scrollTop = this.output.scrollHeight;
    }
}

// Animated Counter
class AnimatedCounter {
    constructor(element) {
        this.element = element;
        this.target = parseInt(element.dataset.target) || 0;
        this.duration = 2000;
        this.start = 0;
        this.startTime = null;
    }

    animate(currentTime) {
        if (!this.startTime) this.startTime = currentTime;

        const progress = Math.min((currentTime - this.startTime) / this.duration, 1);
        const easeOutQuart = 1 - Math.pow(1 - progress, 4);
        const current = Math.floor(easeOutQuart * this.target);

        this.element.textContent = current;

        if (progress < 1) {
            requestAnimationFrame((time) => this.animate(time));
        } else {
            this.element.textContent = this.target;
        }
    }

    start() {
        requestAnimationFrame((time) => this.animate(time));
    }
}

// Scroll Animation Observer
class ScrollAnimator {
    constructor() {
        this.elements = document.querySelectorAll('.animate-on-scroll');
        this.counters = document.querySelectorAll('.stat-number[data-target]');
        this.gainBars = document.querySelectorAll('.gain-bar[data-gain]');
        this.countersAnimated = false;

        this.init();
    }

    init() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach((entry) => {
                if (entry.isIntersecting) {
                    const delay = entry.target.dataset.delay || 0;
                    setTimeout(() => {
                        entry.target.classList.add('visible');
                    }, parseInt(delay));

                    // Animate counters when stats section is visible
                    if (entry.target.closest('.stats-row') && !this.countersAnimated) {
                        this.animateCounters();
                        this.countersAnimated = true;
                    }

                    // Animate gain bars
                    if (entry.target.classList.contains('benchmark-card')) {
                        const gainBar = entry.target.querySelector('.gain-bar');
                        if (gainBar) {
                            const gain = gainBar.dataset.gain;
                            const fill = gainBar.querySelector('.gain-fill');
                            if (fill) {
                                setTimeout(() => {
                                    fill.style.width = `${gain}%`;
                                }, 300);
                            }
                        }
                    }
                }
            });
        }, {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        });

        this.elements.forEach((el) => observer.observe(el));
    }

    animateCounters() {
        this.counters.forEach((counter) => {
            const animator = new AnimatedCounter(counter);
            animator.start();
        });
    }
}

// Initialize Effects
document.addEventListener('DOMContentLoaded', () => {
    new ParticleSystem('particles');
    new TerminalAnimation('terminal-output');
    new ScrollAnimator();
});
