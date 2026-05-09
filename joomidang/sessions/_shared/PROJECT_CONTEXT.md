# 주미당 프로젝트 기술 컨텍스트 (PROJECT_CONTEXT)

> 모든 세션이 읽는 기술 기준 문서. chief 또는 developer가 관리한다.
> 변경 시 날짜와 변경 내용을 이력에 기록한다.

---

## 프로젝트 개요

- **이름**: 주미당(酒美堂) 플랫폼 v2
- **목적**: 한국 전통주(막걸리·소주·약주 등) 역직구 B2C 이커머스
- **핵심 차별점**: IP 기반 국가 감지 → 6개 지역 UX 테마 자동 전환
- **로컬 경로**: `C:\Users\dntmd\OneDrive\바탕 화면\joomidang-v2`
- **GitHub**: (추후 추가)
- **배포**: Vercel (미설정)

---

## 기술 스택

| 영역 | 기술 | 버전 |
|------|------|------|
| Framework | Next.js (App Router) + TypeScript | 16.2.4 |
| DB 호스팅 | Supabase (PostgreSQL) | - |
| ORM | Prisma + PG adapter | 7.8.0 |
| 인증 | NextAuth v5 beta | 5.0.0-beta.31 |
| 상태관리 | Zustand | 5.x |
| 결제 | Stripe | 22.x (API: 2026-04-22.dahlia) |
| CSS | Tailwind CSS | v4 |
| 파일 스토리지 | Supabase Storage | - |
| 배포 | Vercel | - |

---

## ⚠️ Next.js 16 필수 숙지

| 변경 | 내용 |
|------|------|
| middleware.ts | → **proxy.ts**, 함수명도 `proxy` |
| request.geo / request.ip | **완전 제거** → Vercel 헤더 `x-vercel-ip-country` 사용 |
| headers(), cookies(), params, searchParams | 모두 **async** 필수 (`await headers()`) |
| Turbopack | 기본값, webpack config 불가 |

## ⚠️ Prisma 7 필수 숙지

| 변경 | 내용 |
|------|------|
| schema.prisma url/directUrl | **제거됨** → prisma.config.ts로 이동 |
| PrismaClient | `@prisma/adapter-pg` + `pg` Pool 주입 필수 |
| prisma.config.ts | `defineConfig` from `'prisma/config'` |

---

## 프로젝트 구조

```
joomidang-v2/
├── app/
│   ├── (auth)/login/, register/
│   ├── (main)/products/, cart/, checkout/, orders/
│   ├── (seller)/seller/dashboard/, products/
│   ├── (admin)/admin/
│   ├── api/
│   │   ├── auth/[...nextauth]/   # NextAuth 핸들러
│   │   ├── auth/register/        # 회원가입
│   │   ├── geo/                  # IP 국가 감지
│   │   ├── products/             # 상품 CRUD
│   │   ├── cart/                 # 장바구니
│   │   ├── orders/               # 주문
│   │   └── webhooks/stripe/      # 결제 웹훅
│   ├── layout.tsx                # SessionProvider + AgeGate
│   └── page.tsx                  # 메인 (Server Component, 테마 적용)
├── components/
│   ├── common/  Navbar, AgeGate, HeroBanner
│   ├── theme/   KR.ts JP.ts CN.ts US.ts EU.ts SEA.ts Default.ts index.ts
│   ├── products/ProductGrid
│   └── ui/
├── lib/
│   ├── prisma.ts   # Prisma 싱글톤 (PG adapter)
│   ├── geo.ts      # countryToTheme(), fetchCountryCode()
│   └── stripe.ts   # Stripe 클라이언트
├── prisma/schema.prisma
├── prisma.config.ts
├── store/cartStore.ts
├── types/index.ts        # DTO + ok()/fail() 헬퍼
├── auth.ts               # NextAuth v5
└── proxy.ts              # 인증 보호 + Geo 헤더 주입
```

---

## 테마 시스템 플로우

```
HTTP 요청
  → proxy.ts: x-vercel-ip-country → x-country-code 헤더로 전달
  → page.tsx (Server): await headers() → countryToTheme() → getTheme()
  → 컴포넌트에 theme prop 전달 (단일 MainPage, 6개 설정 파일)
```

| 국가 | 테마 | 레퍼런스 |
|------|------|---------|
| KR | KR | 쿠팡 |
| JP | JP | 라쿠텐 |
| CN/HK/TW | CN | 타오바오 |
| US/CA | US | 아마존 |
| EU 국가 | EU | 잘란도 |
| SEA 국가 | SEA | 쇼피 |
| 기타 | DEFAULT | 다크 미니멀 |

---

## DB 스키마 주요 모델

| 모델 | 핵심 필드 |
|------|---------|
| User | id, email, passwordHash, role(CONSUMER/SELLER/ADMIN) |
| Seller | userId, businessName, status(PENDING/APPROVED/SUSPENDED) |
| Product | nameKo/En/Ja/Zh, category, priceKrw(Decimal), stock, status |
| Cart / CartItem | userId, productId, quantity |
| Order / OrderItem | userId, status, totalKrw, shippingAddress(Json), stripePaymentId |
| Review | userId, productId, rating(1-5), content |

---

## API 설계 원칙

```typescript
// 응답 형식 — 항상 ok()/fail() 사용
import { ok, fail } from "@/types";
return NextResponse.json(ok(data));
return NextResponse.json(fail("오류"), { status: 400 });

// 인증 체크
const session = await auth();
if (!session) return NextResponse.json(fail("로그인 필요"), { status: 401 });

// 금액 처리
// DB: Decimal 저장 / JS: Number(p.priceKrw) 변환
```

---

## 환경변수 (.env.local 필요)

```
DATABASE_URL=         # Supabase PostgreSQL (pooler)
DIRECT_URL=           # Supabase PostgreSQL (direct)
AUTH_SECRET=          # NextAuth 비밀키 (32자 이상)
NEXTAUTH_URL=         # http://localhost:3000
STRIPE_SECRET_KEY=    # sk_test_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=  # pk_test_...
STRIPE_WEBHOOK_SECRET=  # whsec_...
```

---

## 현재 구현 상태 (2026-05-07)

| 기능 | 상태 |
|------|------|
| 프로젝트 초기 구조 | ✅ 완료 |
| Prisma 스키마 + 설정 | ✅ 완료 |
| NextAuth v5 인증 구조 | ✅ 완료 |
| 6개국 테마 시스템 | ✅ 완료 |
| 메인 페이지 (Server Component) | ✅ 완료 |
| 로그인/회원가입 페이지 | ✅ 완료 |
| 장바구니 API | ✅ 완료 |
| 상품 목록 API | ✅ 완료 |
| TypeScript 에러 0개 | ✅ 완료 |
| Supabase 연결 (.env.local) | ⏳ 미설정 |
| DB 마이그레이션 | ⏳ 미실행 |
| 상품 상세 페이지 | ❌ 미구현 |
| 장바구니 UI | ❌ 미구현 |
| Stripe 결제 플로우 | ❌ 미구현 |
| 셀러 대시보드 | ❌ 미구현 |
| 이미지 업로드 | ❌ 미구현 |

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-05-07 | 최초 작성 — joomidang-v2 초기 구조 완성 기준 |
