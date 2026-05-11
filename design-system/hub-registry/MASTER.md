# Hub Registry - Design System Master

> **LOGIC:** When building a specific page, first check `design-system/hub-registry/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** Hub Registry
**Style:** Tech / Futuristic / Glassmorphism
**Generated:** 2026-05-06
**Category:** Container Registry SaaS

---

## Global Rules

### Color Palette - 科技蓝主题

| Role | Hex | CSS Variable | Usage |
|------|-----|--------------|-------|
| Tech Blue (Primary) | `#00D4FF` | `--tech-blue` | 主色、强调、边框 |
| Neon Cyan | `#00FFE0` | `--neon-cyan` | 高亮、渐变终点 |
| Tech Blue Dark | `#0066FF` | `--tech-blue-dark` | 深色强调 |
| Tech Blue Light | `#80E5FF` | `--tech-blue-light` | 悬停状态 |
| Background | `#0A0E1A` | `--bg-dark` | 主背景色 |
| Card Background | `rgba(26, 31, 46, 0.85)` | `--bg-card` | 卡片背景 |
| Success | `#00E676` | `--success` | 成功状态 |
| Warning | `#FF9100` | `--warning` | 警告状态 |
| Error | `#FF1744` | `--error` | 错误状态 |
| Text Primary | `#FFFFFF` | `--text-primary` | 主要文字 |
| Text Secondary | `#8B9DC3` | `--text-secondary` | 次要文字 |
| Border Glow | `rgba(0, 212, 255, 0.3)` | `--border-glow` | 发光边框 |

**渐变预设:**
```css
--gradient-primary: linear-gradient(135deg, #00D4FF 0%, #00FFE0 100%);
--gradient-dark: linear-gradient(180deg, rgba(0,212,255,0.1) 0%, transparent 100%);
--gradient-glow: radial-gradient(ellipse at center, rgba(0,212,255,0.15) 0%, transparent 70%);
```

### Typography

- **Heading Font:** Inter, system-ui, sans-serif
- **Body Font:** Inter, system-ui, sans-serif
- **Monospace:** JetBrains Mono, Fira Code (用于日志、代码)
- **Mood:** futuristic, technical, premium, dark, cinematic, precision

**字号规范:**
| 层级 | 大小 | 字重 | 用途 |
|------|------|------|------|
| H1 | 32px | 700 | 页面标题 |
| H2 | 24px | 600 | 区块标题 |
| H3 | 18px | 600 | 卡片标题 |
| Body | 14px | 400 | 正文内容 |
| Small | 12px | 400 | 辅助文字 |
| Code | 13px | 400 | 代码、日志 |

### Spacing Variables

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | `4px` | 紧凑间距 |
| `--space-sm` | `8px` | 元素内边距 |
| `--space-md` | `16px` | 标准间距 |
| `--space-lg` | `24px` | 卡片内边距 |
| `--space-xl` | `32px` | 区块间距 |
| `--space-2xl` | `48px` | 大区块间距 |

### Shadow & Glow Effects

```css
/* 卡片基础阴影 */
--shadow-card: 0 4px 20px rgba(0, 0, 0, 0.3);

/* 悬浮阴影 */
--shadow-hover: 0 8px 32px rgba(0, 0, 0, 0.4),
                0 0 20px rgba(0, 212, 255, 0.1);

/* 选中发光 */
--shadow-active: 0 0 0 2px rgba(0, 212, 255, 0.5),
                 0 0 20px rgba(0, 212, 255, 0.3);

/* Tech Blue 发光 */
--glow-tech: 0 0 10px rgba(0, 212, 255, 0.5),
             0 0 20px rgba(0, 212, 255, 0.3);

/* 强发光 */
--glow-strong: 0 0 20px rgba(0, 212, 255, 0.6),
               0 0 40px rgba(0, 255, 224, 0.4);
```

---

## Core Components

### 玻璃态卡片 (Glass Card)

```css
.glass-card {
  background: rgba(26, 31, 46, 0.8);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(0, 212, 255, 0.15);
  border-radius: 12px;
  box-shadow: var(--shadow-card);
  transition: all 300ms ease;
}

.glass-card:hover {
  border-color: rgba(0, 212, 255, 0.3);
  box-shadow: var(--shadow-hover);
  transform: translateY(-2px);
}
```

### 主按钮 (Tech Button)

```css
.btn-primary {
  background: linear-gradient(135deg, #00D4FF 0%, #00FFE0 100%);
  color: #0A0E1A;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  border: none;
  cursor: pointer;
  transition: all 200ms ease;
  position: relative;
  overflow: hidden;
}

.btn-primary:hover {
  box-shadow: var(--glow-tech);
  transform: scale(1.02);
}

.btn-primary:active {
  transform: scale(0.98);
}
```

### 次要按钮

```css
.btn-secondary {
  background: transparent;
  color: var(--tech-blue);
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 500;
  border: 1px solid rgba(0, 212, 255, 0.5);
  cursor: pointer;
  transition: all 200ms ease;
}

.btn-secondary:hover {
  background: rgba(0, 212, 255, 0.1);
  border-color: var(--tech-blue);
  box-shadow: var(--glow-tech);
}
```

### 输入框

```css
.input {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  padding: 12px 16px;
  color: var(--text-primary);
  font-size: 14px;
  transition: all 200ms ease;
}

.input:focus {
  outline: none;
  border-color: var(--tech-blue);
  box-shadow: 0 0 0 3px rgba(0, 212, 255, 0.2);
  background: rgba(0, 212, 255, 0.05);
}

.input::placeholder {
  color: var(--text-secondary);
}
```

### 状态标签

```css
/* 成功 */
.badge-success {
  background: rgba(0, 230, 118, 0.15);
  color: #00E676;
  border: 1px solid rgba(0, 230, 118, 0.3);
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
}

/* 警告 */
.badge-warning {
  background: rgba(255, 145, 0, 0.15);
  color: #FF9100;
  border: 1px solid rgba(255, 145, 0, 0.3);
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
}

/* 错误 */
.badge-error {
  background: rgba(255, 23, 68, 0.15);
  color: #FF1744;
  border: 1px solid rgba(255, 23, 68, 0.3);
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
}

/* Tech Blue */
.badge-tech {
  background: rgba(0, 212, 255, 0.15);
  color: #00D4FF;
  border: 1px solid rgba(0, 212, 255, 0.3);
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
}
```

---

## Animation System

### 1. 入场动画
```css
@keyframes fadeSlideIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
/* duration: 400ms, easing: ease-out */

@keyframes scaleIn {
  from {
    opacity: 0;
    transform: scale(0.9);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}
/* duration: 300ms, easing: ease-out */
```

### 2. 脉冲动画
```css
@keyframes pulse {
  0%, 100% {
    opacity: 1;
    box-shadow: 0 0 5px var(--color);
  }
  50% {
    opacity: 0.6;
    box-shadow: 0 0 20px var(--color);
  }
}
/* duration: 2s, infinite */

@keyframes pulse-slow {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.8;
    transform: scale(1.05);
  }
}
/* duration: 3s, infinite */
```

### 3. 发光动画
```css
@keyframes glow {
  0%, 100% {
    box-shadow: 0 0 5px var(--tech-blue),
                0 0 10px var(--tech-blue);
  }
  50% {
    box-shadow: 0 0 10px var(--tech-blue),
                0 0 20px var(--neon-cyan),
                0 0 30px var(--neon-cyan);
  }
}
/* duration: 3s, infinite */
```

### 4. 扫描线动画
```css
@keyframes scanline {
  0% {
    transform: translateY(-100%);
  }
  100% {
    transform: translateY(100vh);
  }
}
/* duration: 8s, infinite, linear */
```

### 5. 骨架屏闪光
```css
@keyframes shimmer {
  0% {
    background-position: -200% 0;
  }
  100% {
    background-position: 200% 0;
  }
}
/* duration: 1.5s, infinite */

.skeleton {
  background: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0.05) 25%,
    rgba(255, 255, 255, 0.1) 50%,
    rgba(255, 255, 255, 0.05) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
```

---

## Layout Guidelines

### 页面结构
```
┌──────────────────────────────────────────────────────────────┐
│ 顶部导航栏 (60px)                                              │
├──────────────────┬───────────────────────────────────────────┤
│                  │                                           │
│  侧边栏 (64px)    │           主内容区                        │
│                  │                                           │
│                  │                                           │
│                  │                                           │
└──────────────────┴───────────────────────────────────────────┘
```

### 响应式断点
| 断点 | 宽度 | 布局调整 |
|------|------|---------|
| Mobile | < 768px | 单列，侧边栏隐藏/底部 |
| Tablet | 768px - 1024px | 侧边栏收起，双列卡片 |
| Desktop | > 1024px | 完整布局，多列卡片 |

### 网格系统
```css
/* 卡片网格 */
.grid-cards {
  display: grid;
  gap: 24px;
}

/* Desktop: 4列 */
@media (min-width: 1280px) {
  .grid-cards { grid-template-columns: repeat(4, 1fr); }
}

/* Tablet: 2列 */
@media (min-width: 768px) and (max-width: 1279px) {
  .grid-cards { grid-template-columns: repeat(2, 1fr); }
}

/* Mobile: 1列 */
@media (max-width: 767px) {
  .grid-cards { grid-template-columns: 1fr; }
}
```

---

## Page Directory

### 主要页面设计文档

| 页面 | 文件 | 描述 |
|------|------|------|
| 登录页 | [pages/login.md](pages/login.md) | 科技感登录界面，深色背景配合霓虹光效 |
| 仪表盘 | [pages/dashboard.md](pages/dashboard.md) | 系统总览，健康状态，数据统计 |
| 命名空间 | [pages/namespaces.md](pages/namespaces.md) | 命名空间管理，卡片式列表 |
| 镜像仓库 | [pages/repositories.md](pages/repositories.md) | 仓库管理，卡片/列表视图切换 |
| 镜像复制 | [pages/image-replication.md](pages/image-replication.md) | 复制策略，任务进度，实时日志 |
| 系统状态 | [pages/system-status.md](pages/system-status.md) | 服务监控，资源使用，告警管理 |
| 用户管理 | [pages/user-management.md](pages/user-management.md) | 用户列表，角色权限，操作日志 |

### 通用组件文档

| 文档 | 文件 | 描述 |
|------|------|------|
| 通用组件 | [components/common.md](components/common.md) | 按钮、表单、弹窗、动画规范 |

---

## Icon Guidelines

- **使用 SVG 图标** - 禁止使用 Emoji
- **推荐图标库**: Lucide, Heroicons
- **尺寸规范**:
  - 小图标: 16px
  - 标准图标: 20px
  - 大图标: 24px
  - 页面图标: 40px
- **颜色**: 默认继承文字颜色，可单独设置

---

## Anti-Patterns (禁止使用)

- ❌ **Emoji 作为图标** — 必须使用 SVG
- ❌ **缺少 cursor:pointer** — 所有可点击元素必须设置
- ❌ **布局偏移的悬浮效果** — 避免影响周围元素
- ❌ **低对比度文字** — 保持 4.5:1 最低对比度
- ❌ **瞬时状态变化** — 必须使用过渡动画 (150-300ms)
- ❌ **隐藏的焦点状态** — 必须支持键盘导航
- ❌ **亮色模式** — 本系统仅使用深色模式
- ❌ **圆角过大** — 最大 16px，保持科技感

---

## Pre-Delivery Checklist

交付前必须验证:

- [ ] 无 Emoji 图标，全部使用 SVG
- [ ] 图标风格统一 (Lucide/Heroicons)
- [ ] 所有可点击元素有 `cursor-pointer`
- [ ] 悬浮状态有过渡动画 (150-300ms)
- [ ] 深色模式下文字对比度 4.5:1+
- [ ] 焦点状态可见，支持键盘导航
- [ ] 尊重 `prefers-reduced-motion`
- [ ] 响应式: 375px, 768px, 1024px, 1440px
- [ ] 无内容被固定导航遮挡
- [ ] 移动端无横向滚动
- [ ] 所有颜色使用 CSS 变量
- [ ] 卡片使用玻璃态效果
