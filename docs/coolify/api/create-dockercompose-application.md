---
description: "Deprecated: Use POST /api/v1/services instead."
keywords: Coolify, self hosting, documentation, deployment, Docker, PaaS
lang: en
robots: index,follow
theme-color: "#000000"
title: Create (Docker Compose) \| Coolify Docs
twitter:card: summary_large_image
twitter:description: "Deprecated: Use POST /api/v1/services instead."
twitter:image: "https://coolify.io/docs/og/api-reference/api/applications/create-dockercompose-application.png"
twitter:title: Create (Docker Compose) \| Coolify Docs
viewport: width=device-width, initial-scale=1
---

::: {#nd-docs-layout .grid .overflow-x-clip .min-h-(--fd-docs-height) .[--fd-docs-height:100dvh] .[--fd-header-height:0px] .[--fd-toc-popover-height:0px] .[--fd-sidebar-width:0px] .[--fd-toc-width:0px] .data-[column-changed=true]:transition-[grid-template-columns] sidebar-collapsed="false" column-changed="false" style="grid-template:\"sidebar sidebar header toc toc\"
\"sidebar sidebar toc-popover toc toc\"
\"sidebar sidebar main toc toc\" 1fr / minmax(min-content, 1fr) var(--fd-sidebar-col) minmax(0, calc(var(--fd-layout-width,97rem) - var(--fd-sidebar-width) - var(--fd-toc-width))) var(--fd-toc-width) minmax(min-content, 1fr);--fd-docs-row-1:var(--fd-banner-height, 0px);--fd-docs-row-2:calc(var(--fd-docs-row-1) + var(--fd-header-height));--fd-docs-row-3:calc(var(--fd-docs-row-2) + var(--fd-toc-popover-height));--fd-sidebar-col:var(--fd-sidebar-width)"}
::: {#nd-subnav .[grid-area:header] .sticky .top-(--fd-docs-row-1) .z-30 .flex .items-center .ps-4 .pe-2.5 .border-b .transition-colors .backdrop-blur-sm .h-(--fd-header-height) .md:hidden .max-md:layout:[--fd-header-height:--spacing(14)] .data-[transparent=false]:bg-fd-background/80 transparent="false"}
[![Coolify logo](/docs/brand/logo.webp){.size-6 .rounded-md .border
.border-fd-border/60 .object-cover .shadow-sm}[Coolify]{.font-semibold
.tracking-tight}](/docs/){.inline-flex .items-center .gap-2.5
.font-semibold}

::: flex-1
:::

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXNlYXJjaCIgYXJpYS1oaWRkZW49InRydWUiPjxwYXRoIGQ9Im0yMSAyMS00LjM0LTQuMzQiPjwvcGF0aD48Y2lyY2xlIGN4PSIxMSIgY3k9IjExIiByPSI4Ij48L2NpcmNsZT48L3N2Zz4=){.lucide
.lucide-search}

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXBhbmVsLWxlZnQiIGFyaWEtaGlkZGVuPSJ0cnVlIj48cmVjdCB3aWR0aD0iMTgiIGhlaWdodD0iMTgiIHg9IjMiIHk9IjMiIHJ4PSIyIj48L3JlY3Q+PHBhdGggZD0iTTkgM3YxOCI+PC9wYXRoPjwvc3ZnPg==){.lucide
.lucide-panel-left}
:::

::: {.sticky .top-(--fd-docs-row-1) .z-20 .[grid-area:sidebar] .pointer-events-none .*:pointer-events-auto .h-[calc(var(--fd-docs-height)-var(--fd-docs-row-1))] .md:layout:[--fd-sidebar-width:268px] .max-md:hidden sidebar-placeholder=""}
::: {.flex .flex-col .gap-3 .p-4 .pb-2}
::: flex
[![Coolify logo](/docs/brand/logo.webp){.size-6 .rounded-md .border
.border-fd-border/60 .object-cover .shadow-sm}[Coolify]{.font-semibold
.tracking-tight}](/docs/){.inline-flex .text-[0.9375rem] .items-center
.gap-2.5 .font-medium .me-auto}

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXBhbmVsLWxlZnQiIGFyaWEtaGlkZGVuPSJ0cnVlIj48cmVjdCB3aWR0aD0iMTgiIGhlaWdodD0iMTgiIHg9IjMiIHk9IjMiIHJ4PSIyIj48L3JlY3Q+PHBhdGggZD0iTTkgM3YxOCI+PC9wYXRoPjwvc3ZnPg==){.lucide
.lucide-panel-left}
:::

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXNlYXJjaCBzaXplLTQiIGFyaWEtaGlkZGVuPSJ0cnVlIj48cGF0aCBkPSJtMjEgMjEtNC4zNC00LjM0Ij48L3BhdGg+PGNpcmNsZSBjeD0iMTEiIGN5PSIxMSIgcj0iOCI+PC9jaXJjbGU+PC9zdmc+){.lucide
.lucide-search .size-4}Search

::: {.ms-auto .inline-flex .gap-0.5}
[⌘]{.kbd .rounded-md .border .bg-fd-background .px-1.5}[K]{.kbd
.rounded-md .border .bg-fd-background .px-1.5}
:::
:::

::: {.overflow-hidden .min-h-0 .flex-1 dir="ltr" style="position:relative;--radix-scroll-area-corner-width:0px;--radix-scroll-area-corner-height:0px"}
::: {.size-full .rounded-[inherit] .*:flex! .*:flex-col! .*:gap-0.5! .p-4 .overscroll-contain .mask-[linear-gradient(to_bottom,transparent,white_12px,white_calc(100%-12px),transparent)] radix-scroll-area-viewport="" style="overflow-x:hidden;overflow-y:hidden"}
::: {style="min-width:100%;display:table"}
[![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWV4dGVybmFsLWxpbmsiIGFyaWEtaGlkZGVuPSJ0cnVlIj48cGF0aCBkPSJNMTUgM2g2djYiPjwvcGF0aD48cGF0aCBkPSJNMTAgMTQgMjEgMyI+PC9wYXRoPjxwYXRoIGQ9Ik0xOCAxM3Y2YTIgMiAwIDAgMS0yIDJINWEyIDIgMCAwIDEtMi0yVjhhMiAyIDAgMCAxIDItMmg2Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-external-link}Coolify
Cloud](https://coolify.io/pricing/){.relative .flex .flex-row
.items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors .mb-4
rel="noreferrer noopener" target="_blank" active="false"
style="padding-inline-start:calc(2 * var(--spacing))"}

::: {state="closed"}
[Get
Started]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_39kl6j6_ .overflow-hidden .relative .before:content-[''] .before:absolute .before:w-px .before:inset-y-1 .before:bg-fd-border .before:inset-s-2.5 state="closed" hidden=""}
:::
:::

::: {state="closed"}
[[Applications]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}](/docs/applications){.relative .flex .flex-row
.items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors .w-full active="false"
style="padding-inline-start:calc(2 * var(--spacing))"}

::: {#radix-_R_59kl6j6_ .overflow-hidden .relative .before:content-[''] .before:absolute .before:w-px .before:inset-y-1 .before:bg-fd-border .before:inset-s-2.5 state="closed" hidden=""}
:::
:::

::: {state="closed"}
[[Services]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}](/docs/services/introduction){.relative .flex .flex-row
.items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors .w-full active="false"
style="padding-inline-start:calc(2 * var(--spacing))"}

::: {#radix-_R_79kl6j6_ .overflow-hidden .relative .before:content-[''] .before:absolute .before:w-px .before:inset-y-1 .before:bg-fd-border .before:inset-s-2.5 state="closed" hidden=""}
:::
:::

::: {state="closed"}
[[Databases]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}](/docs/databases){.relative .flex .flex-row
.items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors .w-full active="false"
style="padding-inline-start:calc(2 * var(--spacing))"}

::: {#radix-_R_99kl6j6_ .overflow-hidden .relative .before:content-[''] .before:absolute .before:w-px .before:inset-y-1 .before:bg-fd-border .before:inset-s-2.5 state="closed" hidden=""}
:::
:::

::: {state="closed"}
[Integrations]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_b9kl6j6_ .overflow-hidden .relative .before:content-[''] .before:absolute .before:w-px .before:inset-y-1 .before:bg-fd-border .before:inset-s-2.5 state="closed" hidden=""}
:::
:::

[[Hetzner Promo Code]{.fd-page-tree-item-name}](/docs/hetzner){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors active="false"
style="padding-inline-start:calc(2 * var(--spacing))"}

::: {state="closed"}
[[Knowledge
Base]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}](/docs/knowledge-base){.relative .flex .flex-row
.items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors .w-full active="false"
style="padding-inline-start:calc(2 * var(--spacing))"}

::: {#radix-_R_f9kl6j6_ .overflow-hidden .relative .before:content-[''] .before:absolute .before:w-px .before:inset-y-1 .before:bg-fd-border .before:inset-s-2.5 state="closed" hidden=""}
:::
:::

::: {state="open"}
[API
Reference]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIiBhcmlhLWhpZGRlbj0idHJ1ZSIgZGF0YS1pY29uPSJ0cnVlIj48cGF0aCBkPSJtNiA5IDYgNiA2LTYiPjwvcGF0aD48L3N2Zz4=){.lucide
.lucide-chevron-down .ms-auto .transition-transform}

::: {#radix-_R_h9kl6j6_ .overflow-hidden .relative .before:content-[''] .before:absolute .before:w-px .before:inset-y-1 .before:bg-fd-border .before:inset-s-2.5 state="open"}
::: {.flex .flex-col .gap-0.5 .pt-0.5}
[[Authorization]{.fd-page-tree-item-name}](/docs/api-reference/authorization){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(5 * var(--spacing))"}

::: {state="open"}
[Api]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIiBhcmlhLWhpZGRlbj0idHJ1ZSIgZGF0YS1pY29uPSJ0cnVlIj48cGF0aCBkPSJtNiA5IDYgNiA2LTYiPjwvcGF0aD48L3N2Zz4=){.lucide
.lucide-chevron-down .ms-auto .transition-transform}

::: {#radix-_R_lh9kl6j6_ .overflow-hidden .relative state="open"}
::: {.flex .flex-col .gap-0.5 .pt-0.5}
::: {state="open"}
[Applications]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIiBhcmlhLWhpZGRlbj0idHJ1ZSIgZGF0YS1pY29uPSJ0cnVlIj48cGF0aCBkPSJtNiA5IDYgNiA2LTYiPjwvcGF0aD48L3N2Zz4=){.lucide
.lucide-chevron-down .ms-auto .transition-transform}

::: {#radix-_R_dlh9kl6j6_ .overflow-hidden .relative state="open"}
::: {.flex .flex-col .gap-0.5 .pt-0.5}
[[Create (Docker Compose) [POST]{.font-mono .font-medium .text-blue-600
.dark:text-blue-400 .ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/create-dockercompose-application){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 .active active="true"
style="padding-inline-start:calc(11 * var(--spacing))" status="active"
aria-current="page"}[[Create (Dockerfile without git) [POST]{.font-mono
.font-medium .text-blue-600 .dark:text-blue-400 .ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/create-dockerfile-application){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Create (Docker
Image without git) [POST]{.font-mono .font-medium .text-blue-600
.dark:text-blue-400 .ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/create-dockerimage-application){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Create Env
[POST]{.font-mono .font-medium .text-blue-600 .dark:text-blue-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/create-env-by-application-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Create
(Private - Deploy Key) [POST]{.font-mono .font-medium .text-blue-600
.dark:text-blue-400 .ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/create-private-deploy-key-application){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Create
(Private - GH App) [POST]{.font-mono .font-medium .text-blue-600
.dark:text-blue-400 .ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/create-private-github-app-application){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Create (Public)
[POST]{.font-mono .font-medium .text-blue-600 .dark:text-blue-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/create-public-application){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Delete
[DELETE]{.font-mono .font-medium .text-red-600 .dark:text-red-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/delete-application-by-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Delete Env
[DELETE]{.font-mono .font-medium .text-red-600 .dark:text-red-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/delete-env-by-application-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Get
[GET]{.font-mono .font-medium .text-green-600 .dark:text-green-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/get-application-by-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Get application
logs. [GET]{.font-mono .font-medium .text-green-600 .dark:text-green-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/get-application-logs-by-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[List
[GET]{.font-mono .font-medium .text-green-600 .dark:text-green-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/list-applications){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[List Envs
[GET]{.font-mono .font-medium .text-green-600 .dark:text-green-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/list-envs-by-application-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Restart
[GET]{.font-mono .font-medium .text-green-600 .dark:text-green-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/restart-application-by-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Start
[GET]{.font-mono .font-medium .text-green-600 .dark:text-green-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/start-application-by-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Stop
[GET]{.font-mono .font-medium .text-green-600 .dark:text-green-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/stop-application-by-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Update
[PATCH]{.font-mono .font-medium .text-orange-600 .dark:text-orange-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/update-application-by-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Update Env
[PATCH]{.font-mono .font-medium .text-orange-600 .dark:text-orange-400
.ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/update-env-by-application-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}[[Update Envs
(Bulk) [PATCH]{.font-mono .font-medium .text-orange-600
.dark:text-orange-400 .ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}](/docs/api-reference/api/applications/update-envs-by-application-uuid){.relative
.flex .flex-row .items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors
.data-[active=true]:before:content-['']
.data-[active=true]:before:bg-fd-primary
.data-[active=true]:before:absolute .data-[active=true]:before:w-px
.data-[active=true]:before:inset-y-2.5
.data-[active=true]:before:inset-s-2.5 active="false"
style="padding-inline-start:calc(11 * var(--spacing))"}
:::
:::
:::

::: {state="closed"}
[Cloud
tokens]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_llh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::

::: {state="closed"}
[Databases]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_tlh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::

::: {state="closed"}
[Deployments]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_15lh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::

::: {state="closed"}
[Github
apps]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_1dlh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::

::: {state="closed"}
[Hetzner]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_1llh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::

::: {state="closed"}
[Private
keys]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_1tlh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::

::: {state="closed"}
[Projects]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_25lh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::

::: {state="closed"}
[Resources]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_2dlh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::

::: {state="closed"}
[Servers]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_2llh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::

::: {state="closed"}
[Services]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_2tlh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::

::: {state="closed"}
[System]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_35lh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::

::: {state="closed"}
[Teams]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}

::: {#radix-_R_3dlh9kl6j6_ .overflow-hidden .relative state="closed" hidden=""}
:::
:::
:::
:::
:::
:::
:::
:::

::: {state="closed"}
[[Troubleshoot]{.fd-page-tree-item-name}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHRyYW5zaXRpb24tdHJhbnNmb3JtIC1yb3RhdGUtOTAgcnRsOnJvdGF0ZS05MCIgYXJpYS1oaWRkZW49InRydWUiIGRhdGEtaWNvbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .transition-transform .-rotate-90
.rtl:rotate-90}](/docs/troubleshoot){.relative .flex .flex-row
.items-center .gap-2 .rounded-lg .p-2 .text-start
.text-fd-muted-foreground .wrap-anywhere .[&_svg]:size-4
.[&_svg]:shrink-0 .transition-colors .hover:bg-fd-accent/50
.hover:text-fd-accent-foreground/80 .hover:transition-none
.data-[active=true]:bg-fd-primary/10 .data-[active=true]:text-fd-primary
.data-[active=true]:hover:transition-colors .w-full active="false"
style="padding-inline-start:calc(2 * var(--spacing))"}

::: {#radix-_R_j9kl6j6_ .overflow-hidden .relative .before:content-[''] .before:absolute .before:w-px .before:inset-y-1 .before:bg-fd-border .before:inset-s-2.5 state="closed" hidden=""}
:::
:::
:::
:::
:::

::: {.flex .flex-col .p-4 .pt-2}
::: {.flex .text-fd-muted-foreground .items-center .border .bg-fd-secondary/50 .p-0.5 .pe-0 .rounded-lg .empty:hidden}
[![](data:image/svg+xml;base64,PHN2ZyByb2xlPSJpbWciIHZpZXdib3g9IjAgMCAyNCAyNCIgZmlsbD0iY3VycmVudENvbG9yIiBjbGFzcz0ic2l6ZS00IiBhcmlhLWhpZGRlbj0idHJ1ZSI+PHBhdGggZD0iTTEyIC4yOTdjLTYuNjMgMC0xMiA1LjM3My0xMiAxMiAwIDUuMzAzIDMuNDM4IDkuOCA4LjIwNSAxMS4zODUuNi4xMTMuODItLjI1OC44Mi0uNTc3IDAtLjI4NS0uMDEtMS4wNC0uMDE1LTIuMDQtMy4zMzguNzI0LTQuMDQyLTEuNjEtNC4wNDItMS42MUM0LjQyMiAxOC4wNyAzLjYzMyAxNy43IDMuNjMzIDE3LjdjLTEuMDg3LS43NDQuMDg0LS43MjkuMDg0LS43MjkgMS4yMDUuMDg0IDEuODM4IDEuMjM2IDEuODM4IDEuMjM2IDEuMDcgMS44MzUgMi44MDkgMS4zMDUgMy40OTUuOTk4LjEwOC0uNzc2LjQxNy0xLjMwNS43Ni0xLjYwNS0yLjY2NS0uMy01LjQ2Ni0xLjMzMi01LjQ2Ni01LjkzIDAtMS4zMS40NjUtMi4zOCAxLjIzNS0zLjIyLS4xMzUtLjMwMy0uNTQtMS41MjMuMTA1LTMuMTc2IDAgMCAxLjAwNS0uMzIyIDMuMyAxLjIzLjk2LS4yNjcgMS45OC0uMzk5IDMtLjQwNSAxLjAyLjAwNiAyLjA0LjEzOCAzIC40MDUgMi4yOC0xLjU1MiAzLjI4NS0xLjIzIDMuMjg1LTEuMjMuNjQ1IDEuNjUzLjI0IDIuODczLjEyIDMuMTc2Ljc2NS44NCAxLjIzIDEuOTEgMS4yMyAzLjIyIDAgNC42MS0yLjgwNSA1LjYyNS01LjQ3NSA1LjkyLjQyLjM2LjgxIDEuMDk2LjgxIDIuMjIgMCAxLjYwNi0uMDE1IDIuODk2LS4wMTUgMy4yODYgMCAuMzE1LjIxLjY5LjgyNS41N0MyMC41NjUgMjIuMDkyIDI0IDE3LjU5MiAyNCAxMi4yOTdjMC02LjYyNy01LjM3My0xMi0xMi0xMiI+PC9wYXRoPjwvc3ZnPg==){.size-4}](https://github.com/coollabsio/coolify){.inline-flex
.items-center .justify-center .rounded-md .text-sm .font-medium
.transition-colors .duration-100 .disabled:pointer-events-none
.disabled:opacity-50 .focus-visible:outline-none .focus-visible:ring-2
.focus-visible:ring-fd-ring .hover:bg-fd-accent
.hover:text-fd-accent-foreground .p-1.5 .[&_svg]:size-4.5
rel="noreferrer noopener" target="_blank" aria-label="GitHub"
active="false"}[![](data:image/svg+xml;base64,PHN2ZyByb2xlPSJpbWciIHZpZXdib3g9IjAgMCAyNCAyNCIgZmlsbD0iY3VycmVudENvbG9yIiBjbGFzcz0ic2l6ZS01IiBhcmlhLWhpZGRlbj0idHJ1ZSI+PHBhdGggZD0iTTIwLjMxNyA0LjM2OUExOS43OTEgMTkuNzkxIDAgMCAwIDE1Ljg4NSAzYy0uMTkxLjM0Ny0uNDA4LjgxMy0uNTU4IDEuMTc3YTE4LjI3IDE4LjI3IDAgMCAwLTUuMzA0IDBBMTIuNjQgMTIuNjQgMCAwIDAgOS40NiAzYTE5LjczNiAxOS43MzYgMCAwIDAtNC40MzggMS4zNzJDMi4yMTggOC41MzcgMS40NTYgMTIuNTk2IDEuODM4IDE2LjU5OEExOS45MSAxOS45MSAwIDAgMCA3LjI4NCAxOS4zMmExMy40NDMgMTMuNDQzIDAgMCAwIDEuMTY5LTEuOTA3IDEyLjU5IDEyLjU5IDAgMCAxLTEuODQ0LS44OGMuMTU1LS4xMTQuMzA3LS4yMzMuNDU0LS4zNTUgMy41NTUgMS42NCA3LjQxNCAxLjY0IDEwLjkyNyAwIC4xNS4xMjIuMzAyLjI0LjQ1NC4zNTUtLjU5My4zNDgtMS4yMS42NDQtMS44NDQuODguMzQuNjYuNzMgMS4yOTYgMS4xNyAxLjkwN2ExOS44OCAxOS44OCAwIDAgMCA1LjQ1LTIuNzIyYy40NTYtNC42NC0uNzgtOC42NjQtMy45MDMtMTIuMjNNOC4wMiAxNC4xNzZjLTEuMDY2IDAtMS45NC0uOTgtMS45NC0yLjE4NSAwLTEuMjA2Ljg1Ny0yLjE4NSAxLjk0LTIuMTg1IDEuMDkyIDAgMS45NTcuOTg4IDEuOTQgMi4xODUgMCAxLjIwNi0uODU3IDIuMTg1LTEuOTQgMi4xODVtNy4xNCAwYy0xLjA2NyAwLTEuOTQtLjk4LTEuOTQtMi4xODUgMC0xLjIwNi44NTYtMi4xODUgMS45NC0yLjE4NSAxLjA5MSAwIDEuOTU2Ljk4OCAxLjkzOSAyLjE4NSAwIDEuMjA2LS44NDggMi4xODUtMS45NCAyLjE4NSI+PC9wYXRoPjwvc3ZnPg==){.size-5}](https://coollabs.io/discord){.inline-flex
.items-center .justify-center .rounded-md .text-sm .font-medium
.transition-colors .duration-100 .disabled:pointer-events-none
.disabled:opacity-50 .focus-visible:outline-none .focus-visible:ring-2
.focus-visible:ring-fd-ring .hover:bg-fd-accent
.hover:text-fd-accent-foreground .p-1.5 .[&_svg]:size-4.5
rel="noreferrer noopener" target="_blank" aria-label="Discord"
active="false"}

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJjdXJyZW50Q29sb3IiIHN0cm9rZT0iY3VycmVudENvbG9yIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIgY2xhc3M9Imx1Y2lkZSBsdWNpZGUtc3VuIHNpemUtNi41IHAtMS41IHRleHQtZmQtbXV0ZWQtZm9yZWdyb3VuZCIgYXJpYS1oaWRkZW49InRydWUiPjxjaXJjbGUgY3g9IjEyIiBjeT0iMTIiIHI9IjQiPjwvY2lyY2xlPjxwYXRoIGQ9Ik0xMiAydjIiPjwvcGF0aD48cGF0aCBkPSJNMTIgMjB2MiI+PC9wYXRoPjxwYXRoIGQ9Im00LjkzIDQuOTMgMS40MSAxLjQxIj48L3BhdGg+PHBhdGggZD0ibTE3LjY2IDE3LjY2IDEuNDEgMS40MSI+PC9wYXRoPjxwYXRoIGQ9Ik0yIDEyaDIiPjwvcGF0aD48cGF0aCBkPSJNMjAgMTJoMiI+PC9wYXRoPjxwYXRoIGQ9Im02LjM0IDE3LjY2LTEuNDEgMS40MSI+PC9wYXRoPjxwYXRoIGQ9Im0xOS4wNyA0LjkzLTEuNDEgMS40MSI+PC9wYXRoPjwvc3ZnPg==){.lucide
.lucide-sun .size-6.5 .p-1.5
.text-fd-muted-foreground}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJjdXJyZW50Q29sb3IiIHN0cm9rZT0iY3VycmVudENvbG9yIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIgY2xhc3M9Imx1Y2lkZSBsdWNpZGUtbW9vbiBzaXplLTYuNSBwLTEuNSB0ZXh0LWZkLW11dGVkLWZvcmVncm91bmQiIGFyaWEtaGlkZGVuPSJ0cnVlIj48cGF0aCBkPSJNMjAuOTg1IDEyLjQ4NmE5IDkgMCAxIDEtOS40NzMtOS40NzJjLjQwNS0uMDIyLjYxNy40Ni40MDIuODAzYTYgNiAwIDAgMCA4LjI2OCA4LjI2OGMuMzQ0LS4yMTUuODI1LS4wMDQuODAzLjQwMSI+PC9wYXRoPjwvc3ZnPg==){.lucide
.lucide-moon .size-6.5 .p-1.5 .text-fd-muted-foreground}
:::
:::
:::

::: {.fixed .flex .top-[calc(--spacing(4)+var(--fd-docs-row-3))] .inset-s-4 .shadow-lg .transition-opacity .rounded-xl .p-0.5 .border .bg-fd-muted .text-fd-muted-foreground .z-10 .pointer-events-none .opacity-0 sidebar-panel=""}
![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXBhbmVsLWxlZnQiIGFyaWEtaGlkZGVuPSJ0cnVlIj48cmVjdCB3aWR0aD0iMTgiIGhlaWdodD0iMTgiIHg9IjMiIHk9IjMiIHJ4PSIyIj48L3JlY3Q+PHBhdGggZD0iTTkgM3YxOCI+PC9wYXRoPjwvc3ZnPg==){.lucide
.lucide-panel-left}

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXNlYXJjaCIgYXJpYS1oaWRkZW49InRydWUiPjxwYXRoIGQ9Im0yMSAyMS00LjM0LTQuMzQiPjwvcGF0aD48Y2lyY2xlIGN4PSIxMSIgY3k9IjExIiByPSI4Ij48L2NpcmNsZT48L3N2Zz4=){.lucide
.lucide-search}
:::

::: {.prose .flex-1}
::: {.flex .flex-col .gap-24 .text-sm .@container}
::: {.flex .flex-col .gap-x-6 .gap-y-4 .@4xl:flex-row .@4xl:items-start}
::: {.min-w-0 .flex-1}
[Server URL]{.px-2 .py-0.5 .-ms-2 .font-medium .rounded-lg .border
.bg-fd-secondary .text-fd-secondary-foreground
.shadow-sm}`loading...`{.truncate .min-w-0
.flex-1}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLXNxdWFyZS1wZW4gc2l6ZS00IiBhcmlhLWhpZGRlbj0idHJ1ZSI+PHBhdGggZD0iTTEyIDNINWEyIDIgMCAwIDAtMiAydjE0YTIgMiAwIDAgMCAyIDJoMTRhMiAyIDAgMCAwIDItMnYtNyI+PC9wYXRoPjxwYXRoIGQ9Ik0xOC4zNzUgMi42MjVhMSAxIDAgMCAxIDMgM2wtOS4wMTMgOS4wMTRhMiAyIDAgMCAxLS44NTMuNTA1bC0yLjg3My44NGEuNS41IDAgMCAxLS42Mi0uNjJsLjg0LTIuODczYTIgMiAwIDAgMSAuNTA2LS44NTJ6Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-square-pen .size-4}

::: {.flex .flex-row .items-center .gap-2 .text-sm .p-3 .not-last:pb-0}
[POST]{.font-mono .font-medium .text-blue-600 .dark:text-blue-400}

::: {.flex .flex-row .items-center .gap-0.5 .overflow-auto .text-nowrap .flex-1}
[/]{.text-fd-muted-foreground}`applications`{.text-fd-foreground}[/]{.text-fd-muted-foreground}`dockercompose`{.text-fd-foreground}
:::

Send
:::

::: {.border-b .last:border-b-0 state="closed" data-type="authorization"}
Authorization![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHNpemUtMy41IHRleHQtZmQtbXV0ZWQtZm9yZWdyb3VuZCBncm91cC1kYXRhLVtzdGF0ZT1vcGVuXTpyb3RhdGUtMTgwIiBhcmlhLWhpZGRlbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .size-3.5 .text-fd-muted-foreground
.group-data-[state=open]:rotate-180}

::: {#radix-_R_gjda6j6_ .overflow-hidden state="closed" hidden=""}
:::
:::

::: {.border-b .last:border-b-0 state="closed" data-type="body"}
Body![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tZG93biBtcy1hdXRvIHNpemUtMy41IHRleHQtZmQtbXV0ZWQtZm9yZWdyb3VuZCBncm91cC1kYXRhLVtzdGF0ZT1vcGVuXTpyb3RhdGUtMTgwIiBhcmlhLWhpZGRlbj0idHJ1ZSI+PHBhdGggZD0ibTYgOSA2IDYgNi02Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-chevron-down .ms-auto .size-3.5 .text-fd-muted-foreground
.group-data-[state=open]:rotate-180}

::: {#radix-_R_ojda6j6_ .overflow-hidden state="closed" hidden=""}
:::
:::

Deprecated: Use POST /api/v1/services instead.

::: {.flex .items-start .justify-between .gap-2 .mt-10}
## [Authorization](#authorization){.peer card=""}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWxpbmsgc2l6ZS0zLjUgc2hyaW5rLTAgdGV4dC1mZC1tdXRlZC1mb3JlZ3JvdW5kIG9wYWNpdHktMCB0cmFuc2l0aW9uLW9wYWNpdHkgcGVlci1ob3ZlcjpvcGFjaXR5LTEwMCIgYXJpYS1oaWRkZW49InRydWUiPjxwYXRoIGQ9Ik0xMCAxM2E1IDUgMCAwIDAgNy41NC41NGwzLTNhNSA1IDAgMCAwLTcuMDctNy4wN2wtMS43MiAxLjcxIj48L3BhdGg+PHBhdGggZD0iTTE0IDExYTUgNSAwIDAgMC03LjU0LS41NGwtMyAzYTUgNSAwIDAgMCA3LjA3IDcuMDdsMS43MS0xLjcxIj48L3BhdGg+PC9zdmc+){.lucide .lucide-link .size-3.5 .shrink-0 .text-fd-muted-foreground .opacity-0 .transition-opacity .peer-hover:opacity-100} {#authorization .flex .scroll-m-28 .flex-row .items-center .gap-2 .my-0!}

::: not-prose
::: {.flex .flex-col .text-xs .min-w-0}
[`bearerAuth`{.truncate}]{.font-medium}` `{.truncate}
:::
:::
:::

<div>

::: {.text-sm .border-t .my-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[Authorization]{.font-medium .font-mono .text-fd-primary}[Bearer
\<token\>]{.text-sm .font-mono .text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
Go to `Keys & Tokens` / `API tokens` and create a new token. Use the
token as the bearer token.

In: `header`
:::
:::

</div>

::: {.flex .gap-2 .items-center .justify-between .mt-10}
## [Request Body](#request-body){.peer card=""}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWxpbmsgc2l6ZS0zLjUgc2hyaW5rLTAgdGV4dC1mZC1tdXRlZC1mb3JlZ3JvdW5kIG9wYWNpdHktMCB0cmFuc2l0aW9uLW9wYWNpdHkgcGVlci1ob3ZlcjpvcGFjaXR5LTEwMCIgYXJpYS1oaWRkZW49InRydWUiPjxwYXRoIGQ9Ik0xMCAxM2E1IDUgMCAwIDAgNy41NC41NGwzLTNhNSA1IDAgMCAwLTcuMDctNy4wN2wtMS43MiAxLjcxIj48L3BhdGg+PHBhdGggZD0iTTE0IDExYTUgNSAwIDAgMC03LjU0LS41NGwtMyAzYTUgNSAwIDAgMCA3LjA3IDcuMDdsMS43MS0xLjcxIj48L3BhdGg+PC9zdmc+){.lucide .lucide-link .size-3.5 .shrink-0 .text-fd-muted-foreground .opacity-0 .transition-opacity .peer-hover:opacity-100} {#request-body .flex .scroll-m-28 .flex-row .items-center .gap-2 .my-0!}

`application/json`{.text-xs}
:::

Application object that needs to be created.

<div>

::: {.flex .items-start .justify-between .gap-2 .bg-fd-card .text-fd-card-foreground .border .rounded-xl .p-3 .not-prose .mb-4 .last:mb-0 .mt-4}
<div>

TypeScript Definitions

Use the request body type in TypeScript.

</div>

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNvcHkgc2l6ZS0zLjUiIGFyaWEtaGlkZGVuPSJ0cnVlIj48cmVjdCB3aWR0aD0iMTQiIGhlaWdodD0iMTQiIHg9IjgiIHk9IjgiIHJ4PSIyIiByeT0iMiI+PC9yZWN0PjxwYXRoIGQ9Ik00IDE2Yy0xLjEgMC0yLS45LTItMlY0YzAtMS4xLjktMiAyLTJoMTBjMS4xIDAgMiAuOSAyIDIiPjwvcGF0aD48L3N2Zz4=){.lucide
.lucide-copy .size-3.5}Copy
:::

::: {.flex .items-center .border .my-2 .rounded-md .bg-fd-secondary .text-fd-secondary-foreground .transition-colors .shadow-sm .focus-within:ring-2 .focus-within:ring-fd-ring}
![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWZ1bm5lbCB0ZXh0LWZkLW11dGVkLWZvcmVncm91bmQgbXMtMiBzaXplLTMuNSIgYXJpYS1oaWRkZW49InRydWUiPjxwYXRoIGQ9Ik0xMCAyMGExIDEgMCAwIDAgLjU1My44OTVsMiAxQTEgMSAwIDAgMCAxNCAyMXYtN2EyIDIgMCAwIDEgLjUxNy0xLjM0MUwyMS43NCA0LjY3QTEgMSAwIDAgMCAyMSAzSDNhMSAxIDAgMCAwLS43NDIgMS42N2w3LjIyNSA3Ljk4OUEyIDIgMCAwIDEgMTAgMTR6Ij48L3BhdGg+PC9zdmc+){.lucide
.lucide-funnel .text-fd-muted-foreground .ms-2 .size-3.5}
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[project_uuid[\*]{.text-red-400}]{.font-medium .font-mono
.text-fd-primary}[string]{.text-sm .font-mono .text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
The project UUID.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[server_uuid[\*]{.text-red-400}]{.font-medium .font-mono
.text-fd-primary}[string]{.text-sm .font-mono .text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
The server UUID.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[environment_name[\*]{.text-red-400}]{.font-medium .font-mono
.text-fd-primary}[string]{.text-sm .font-mono .text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
The environment name. You need to provide at least one of
environment_name or environment_uuid.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[environment_uuid[\*]{.text-red-400}]{.font-medium .font-mono
.text-fd-primary}[string]{.text-sm .font-mono .text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
The environment UUID. You need to provide at least one of
environment_name or environment_uuid.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[docker_compose_raw[\*]{.text-red-400}]{.font-medium .font-mono
.text-fd-primary}[string]{.text-sm .font-mono .text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
The Docker Compose raw content.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[destination_uuid[?]{.text-fd-muted-foreground}]{.font-medium .font-mono
.text-fd-primary}[string]{.text-sm .font-mono .text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
The destination UUID if the server has more than one destinations.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[name[?]{.text-fd-muted-foreground}]{.font-medium .font-mono
.text-fd-primary}[string]{.text-sm .font-mono .text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
The application name.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[description[?]{.text-fd-muted-foreground}]{.font-medium .font-mono
.text-fd-primary}[string]{.text-sm .font-mono .text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
The application description.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[instant_deploy[?]{.text-fd-muted-foreground}]{.font-medium .font-mono
.text-fd-primary}[boolean]{.text-sm .font-mono
.text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
The flag to indicate if the application should be deployed instantly.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[use_build_server[?]{.text-fd-muted-foreground}]{.font-medium .font-mono
.text-fd-primary}[boolean]{.text-sm .font-mono
.text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
Use build server.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[connect_to_docker_network[?]{.text-fd-muted-foreground}]{.font-medium
.font-mono .text-fd-primary}[boolean]{.text-sm .font-mono
.text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
The flag to connect the service to the predefined Docker network.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[force_domain_override[?]{.text-fd-muted-foreground}]{.font-medium
.font-mono .text-fd-primary}[boolean]{.text-sm .font-mono
.text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
Force domain usage even if conflicts are detected. Default is false.
:::
:::

::: {.text-sm .border-t .py-4 .first:border-t-0}
::: {.flex .flex-wrap .items-center .gap-3 .not-prose}
[is_container_label_escape_enabled[?]{.text-fd-muted-foreground}]{.font-medium
.font-mono .text-fd-primary}[boolean]{.text-sm .font-mono
.text-fd-muted-foreground}
:::

::: {.prose-no-margin .pt-2.5 .empty:hidden}
Escape special characters in labels. By default, \$ (and other chars) is
escaped. So if you write \$ in the labels, it will be saved as \$\$. If
you want to use env variables inside the labels, turn this off.

::: {.flex .flex-row .gap-2 .flex-wrap .my-2 .not-prose .empty:hidden}
::: {.flex .flex-row .items-start .gap-2 .bg-fd-secondary .border .rounded-lg .text-xs .p-1.5 .shadow-md .max-w-full}
[Default]{.font-medium}`true`{.min-w-0 .flex-1 .text-fd-muted-foreground
.truncate}
:::
:::
:::
:::

</div>

## [Response Body](#response-body){.peer card=""}![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWxpbmsgc2l6ZS0zLjUgc2hyaW5rLTAgdGV4dC1mZC1tdXRlZC1mb3JlZ3JvdW5kIG9wYWNpdHktMCB0cmFuc2l0aW9uLW9wYWNpdHkgcGVlci1ob3ZlcjpvcGFjaXR5LTEwMCIgYXJpYS1oaWRkZW49InRydWUiPjxwYXRoIGQ9Ik0xMCAxM2E1IDUgMCAwIDAgNy41NC41NGwzLTNhNSA1IDAgMCAwLTcuMDctNy4wN2wtMS43MiAxLjcxIj48L3BhdGg+PHBhdGggZD0iTTE0IDExYTUgNSAwIDAgMC03LjU0LS41NGwtMyAzYTUgNSAwIDAgMCA3LjA3IDcuMDdsMS43MS0xLjcxIj48L3BhdGg+PC9zdmc+){.lucide .lucide-link .size-3.5 .shrink-0 .text-fd-muted-foreground .opacity-0 .transition-opacity .peer-hover:opacity-100} {#response-body .flex .scroll-m-28 .flex-row .items-center .gap-2}

::: {.divide-y .divide-fd-border orientation="vertical"}
::: {.scroll-m-20 state="closed" orientation="vertical"}
### ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tcmlnaHQgc2l6ZS0zLjUgdGV4dC1mZC1tdXRlZC1mb3JlZ3JvdW5kIHNocmluay0wIHRyYW5zaXRpb24tdHJhbnNmb3JtIGdyb3VwLWZvY3VzLXZpc2libGUvYWNjb3JkaW9uOnRleHQtZmQtcHJpbWFyeSBncm91cC1kYXRhLVtzdGF0ZT1vcGVuXS9hY2NvcmRpb246cm90YXRlLTkwIiBhcmlhLWhpZGRlbj0idHJ1ZSI+PHBhdGggZD0ibTkgMTggNi02LTYtNiI+PC9wYXRoPjwvc3ZnPg==){.lucide .lucide-chevron-right .size-3.5 .text-fd-muted-foreground .shrink-0 .transition-transform .group-focus-visible/accordion:text-fd-primary .group-data-[state=open]/accordion:rotate-90}201 {#section .not-prose .flex .py-2 .text-fd-foreground .font-medium orientation="vertical" state="closed"}

`application/json`{.text-xs}

::: {#radix-_R_4prda6j6_ .overflow-hidden .data-[state=closed]:animate-fd-accordion-up .data-[state=open]:animate-fd-accordion-down .ps-4.5 state="closed" hidden="" role="region" aria-labelledby="radix-_R_prda6j6_" orientation="vertical" style="--radix-accordion-content-height:var(--radix-collapsible-content-height);--radix-accordion-content-width:var(--radix-collapsible-content-width)"}
:::
:::

::: {.scroll-m-20 state="closed" orientation="vertical"}
### ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tcmlnaHQgc2l6ZS0zLjUgdGV4dC1mZC1tdXRlZC1mb3JlZ3JvdW5kIHNocmluay0wIHRyYW5zaXRpb24tdHJhbnNmb3JtIGdyb3VwLWZvY3VzLXZpc2libGUvYWNjb3JkaW9uOnRleHQtZmQtcHJpbWFyeSBncm91cC1kYXRhLVtzdGF0ZT1vcGVuXS9hY2NvcmRpb246cm90YXRlLTkwIiBhcmlhLWhpZGRlbj0idHJ1ZSI+PHBhdGggZD0ibTkgMTggNi02LTYtNiI+PC9wYXRoPjwvc3ZnPg==){.lucide .lucide-chevron-right .size-3.5 .text-fd-muted-foreground .shrink-0 .transition-transform .group-focus-visible/accordion:text-fd-primary .group-data-[state=open]/accordion:rotate-90}400 {#section-1 .not-prose .flex .py-2 .text-fd-foreground .font-medium orientation="vertical" state="closed"}

`application/json`{.text-xs}

::: {#radix-_R_59rda6j6_ .overflow-hidden .data-[state=closed]:animate-fd-accordion-up .data-[state=open]:animate-fd-accordion-down .ps-4.5 state="closed" hidden="" role="region" aria-labelledby="radix-_R_19rda6j6_" orientation="vertical" style="--radix-accordion-content-height:var(--radix-collapsible-content-height);--radix-accordion-content-width:var(--radix-collapsible-content-width)"}
:::
:::

::: {.scroll-m-20 state="closed" orientation="vertical"}
### ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tcmlnaHQgc2l6ZS0zLjUgdGV4dC1mZC1tdXRlZC1mb3JlZ3JvdW5kIHNocmluay0wIHRyYW5zaXRpb24tdHJhbnNmb3JtIGdyb3VwLWZvY3VzLXZpc2libGUvYWNjb3JkaW9uOnRleHQtZmQtcHJpbWFyeSBncm91cC1kYXRhLVtzdGF0ZT1vcGVuXS9hY2NvcmRpb246cm90YXRlLTkwIiBhcmlhLWhpZGRlbj0idHJ1ZSI+PHBhdGggZD0ibTkgMTggNi02LTYtNiI+PC9wYXRoPjwvc3ZnPg==){.lucide .lucide-chevron-right .size-3.5 .text-fd-muted-foreground .shrink-0 .transition-transform .group-focus-visible/accordion:text-fd-primary .group-data-[state=open]/accordion:rotate-90}401 {#section-2 .not-prose .flex .py-2 .text-fd-foreground .font-medium orientation="vertical" state="closed"}

`application/json`{.text-xs}

::: {#radix-_R_5prda6j6_ .overflow-hidden .data-[state=closed]:animate-fd-accordion-up .data-[state=open]:animate-fd-accordion-down .ps-4.5 state="closed" hidden="" role="region" aria-labelledby="radix-_R_1prda6j6_" orientation="vertical" style="--radix-accordion-content-height:var(--radix-collapsible-content-height);--radix-accordion-content-width:var(--radix-collapsible-content-width)"}
:::
:::

::: {.scroll-m-20 state="closed" orientation="vertical"}
### ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tcmlnaHQgc2l6ZS0zLjUgdGV4dC1mZC1tdXRlZC1mb3JlZ3JvdW5kIHNocmluay0wIHRyYW5zaXRpb24tdHJhbnNmb3JtIGdyb3VwLWZvY3VzLXZpc2libGUvYWNjb3JkaW9uOnRleHQtZmQtcHJpbWFyeSBncm91cC1kYXRhLVtzdGF0ZT1vcGVuXS9hY2NvcmRpb246cm90YXRlLTkwIiBhcmlhLWhpZGRlbj0idHJ1ZSI+PHBhdGggZD0ibTkgMTggNi02LTYtNiI+PC9wYXRoPjwvc3ZnPg==){.lucide .lucide-chevron-right .size-3.5 .text-fd-muted-foreground .shrink-0 .transition-transform .group-focus-visible/accordion:text-fd-primary .group-data-[state=open]/accordion:rotate-90}409 {#section-3 .not-prose .flex .py-2 .text-fd-foreground .font-medium orientation="vertical" state="closed"}

`application/json`{.text-xs}

::: {#radix-_R_69rda6j6_ .overflow-hidden .data-[state=closed]:animate-fd-accordion-up .data-[state=open]:animate-fd-accordion-down .ps-4.5 state="closed" hidden="" role="region" aria-labelledby="radix-_R_29rda6j6_" orientation="vertical" style="--radix-accordion-content-height:var(--radix-collapsible-content-height);--radix-accordion-content-width:var(--radix-collapsible-content-width)"}
:::
:::
:::
:::

::: {.@4xl:sticky .@4xl:top-[calc(var(--fd-docs-row-1,2rem)+1rem)] .@4xl:w-[400px]}
::: prose-no-margin
::: {.bg-fd-card .rounded-xl .border .my-4 dir="ltr" orientation="horizontal"}
::: {.flex .flex-row .px-2 .overflow-x-auto .text-fd-muted-foreground role="tablist" aria-orientation="horizontal" tabindex="-1" orientation="horizontal" style="outline:none"}
::: {.absolute .inset-x-2 .bottom-0 .h-px .group-data-[state=active]:bg-fd-primary}
:::

cURL

::: {.absolute .inset-x-2 .bottom-0 .h-px .group-data-[state=active]:bg-fd-primary}
:::

JavaScript

::: {.absolute .inset-x-2 .bottom-0 .h-px .group-data-[state=active]:bg-fd-primary}
:::

Go

::: {.absolute .inset-x-2 .bottom-0 .h-px .group-data-[state=active]:bg-fd-primary}
:::

Python

::: {.absolute .inset-x-2 .bottom-0 .h-px .group-data-[state=active]:bg-fd-primary}
:::

Java

::: {.absolute .inset-x-2 .bottom-0 .h-px .group-data-[state=active]:bg-fd-primary}
:::

C#
:::

::: {#radix-_R_lda6j6_-content-curl state="active" orientation="horizontal" role="tabpanel" aria-labelledby="radix-_R_lda6j6_-trigger-curl" tabindex="0" style="animation-duration:0s"}
<figure
class="bg-fd-secondary -mx-px last:rounded-b-xl shiki relative border shadow-sm not-prose overflow-hidden text-sm my-0"
dir="ltr" tabindex="-1">
<div
class="empty:hidden absolute top-3 right-2 z-2 backdrop-blur-lg rounded-lg text-fd-muted-foreground">
<img
src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNsaXBib2FyZCIgYXJpYS1oaWRkZW49InRydWUiPjxyZWN0IHdpZHRoPSI4IiBoZWlnaHQ9IjQiIHg9IjgiIHk9IjIiIHJ4PSIxIiByeT0iMSI+PC9yZWN0PjxwYXRoIGQ9Ik0xNiA0aDJhMiAyIDAgMCAxIDIgMnYxNGEyIDIgMCAwIDEtMiAySDZhMiAyIDAgMCAxLTItMlY2YTIgMiAwIDAgMSAyLTJoMiI+PC9wYXRoPjwvc3ZnPg=="
class="lucide lucide-clipboard" />
</div>
<div
class="text-[0.8125rem] py-3.5 overflow-auto max-h-[600px] fd-scroll-container focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-fd-ring"
role="region" tabindex="0"
style="--padding-right:calc(var(--spacing) * 8)">
<pre class="min-w-full w-max *:flex *:flex-col"><code>curl -X POST &quot;https://app.coolify.io/api/v1/applications/dockercompose&quot; \  -H &quot;Content-Type: application/json&quot; \  -d &#39;{    &quot;project_uuid&quot;: &quot;string&quot;,    &quot;server_uuid&quot;: &quot;string&quot;,    &quot;environment_name&quot;: &quot;string&quot;,    &quot;environment_uuid&quot;: &quot;string&quot;,    &quot;docker_compose_raw&quot;: &quot;string&quot;  }&#39;</code></pre>
</div>
</figure>
:::

::: {#radix-_R_lda6j6_-content-js state="inactive" orientation="horizontal" role="tabpanel" aria-labelledby="radix-_R_lda6j6_-trigger-js" hidden="" tabindex="0"}
:::

::: {#radix-_R_lda6j6_-content-go state="inactive" orientation="horizontal" role="tabpanel" aria-labelledby="radix-_R_lda6j6_-trigger-go" hidden="" tabindex="0"}
:::

::: {#radix-_R_lda6j6_-content-python state="inactive" orientation="horizontal" role="tabpanel" aria-labelledby="radix-_R_lda6j6_-trigger-python" hidden="" tabindex="0"}
:::

::: {#radix-_R_lda6j6_-content-java state="inactive" orientation="horizontal" role="tabpanel" aria-labelledby="radix-_R_lda6j6_-trigger-java" hidden="" tabindex="0"}
:::

::: {#radix-_R_lda6j6_-content-csharp state="inactive" orientation="horizontal" role="tabpanel" aria-labelledby="radix-_R_lda6j6_-trigger-csharp" hidden="" tabindex="0"}
:::
:::

::: {.flex .flex-col .overflow-hidden .rounded-xl .border .bg-fd-secondary .my-4 dir="ltr" orientation="horizontal"}
::: {.flex .gap-3.5 .text-fd-secondary-foreground .overflow-x-auto .px-4 .not-prose role="tablist" aria-orientation="horizontal" tabindex="-1" orientation="horizontal" style="outline:none"}
201

400

401

409
:::

::: {#radix-_R_tda6j6_-content-201 .p-4 .text-[0.9375rem] .bg-fd-background .rounded-xl .outline-none .prose-no-margin .data-[state=inactive]:hidden .[&>figure:only-child]:-m-4 .[&>figure:only-child]:border-none state="active" orientation="horizontal" role="tabpanel" aria-labelledby="radix-_R_tda6j6_-trigger-201" tabindex="0" style="animation-duration:0s"}
<figure
class="bg-fd-card rounded-xl shiki relative border shadow-sm not-prose overflow-hidden text-sm my-0"
dir="ltr" tabindex="-1">
<div
class="empty:hidden absolute top-3 right-2 z-2 backdrop-blur-lg rounded-lg text-fd-muted-foreground">
<img
src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNsaXBib2FyZCIgYXJpYS1oaWRkZW49InRydWUiPjxyZWN0IHdpZHRoPSI4IiBoZWlnaHQ9IjQiIHg9IjgiIHk9IjIiIHJ4PSIxIiByeT0iMSI+PC9yZWN0PjxwYXRoIGQ9Ik0xNiA0aDJhMiAyIDAgMCAxIDIgMnYxNGEyIDIgMCAwIDEtMiAySDZhMiAyIDAgMCAxLTItMlY2YTIgMiAwIDAgMSAyLTJoMiI+PC9wYXRoPjwvc3ZnPg=="
class="lucide lucide-clipboard" />
</div>
<div
class="text-[0.8125rem] py-3.5 overflow-auto max-h-[600px] fd-scroll-container focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-fd-ring"
role="region" tabindex="0"
style="--padding-right:calc(var(--spacing) * 8)">
<pre class="min-w-full w-max *:flex *:flex-col"><code>{  &quot;uuid&quot;: &quot;string&quot;}</code></pre>
</div>
</figure>
:::

::: {#radix-_R_tda6j6_-content-400 .p-4 .text-[0.9375rem] .bg-fd-background .rounded-xl .outline-none .prose-no-margin .data-[state=inactive]:hidden .[&>figure:only-child]:-m-4 .[&>figure:only-child]:border-none state="inactive" orientation="horizontal" role="tabpanel" aria-labelledby="radix-_R_tda6j6_-trigger-400" tabindex="0"}
<figure
class="bg-fd-card rounded-xl shiki relative border shadow-sm not-prose overflow-hidden text-sm my-0"
dir="ltr" tabindex="-1">
<div
class="empty:hidden absolute top-3 right-2 z-2 backdrop-blur-lg rounded-lg text-fd-muted-foreground">
<img
src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNsaXBib2FyZCIgYXJpYS1oaWRkZW49InRydWUiPjxyZWN0IHdpZHRoPSI4IiBoZWlnaHQ9IjQiIHg9IjgiIHk9IjIiIHJ4PSIxIiByeT0iMSI+PC9yZWN0PjxwYXRoIGQ9Ik0xNiA0aDJhMiAyIDAgMCAxIDIgMnYxNGEyIDIgMCAwIDEtMiAySDZhMiAyIDAgMCAxLTItMlY2YTIgMiAwIDAgMSAyLTJoMiI+PC9wYXRoPjwvc3ZnPg=="
class="lucide lucide-clipboard" />
</div>
<div
class="text-[0.8125rem] py-3.5 overflow-auto max-h-[600px] fd-scroll-container focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-fd-ring"
role="region" tabindex="0"
style="--padding-right:calc(var(--spacing) * 8)">
<pre class="min-w-full w-max *:flex *:flex-col"><code>{  &quot;message&quot;: &quot;Invalid token.&quot;}</code></pre>
</div>
</figure>
:::

::: {#radix-_R_tda6j6_-content-401 .p-4 .text-[0.9375rem] .bg-fd-background .rounded-xl .outline-none .prose-no-margin .data-[state=inactive]:hidden .[&>figure:only-child]:-m-4 .[&>figure:only-child]:border-none state="inactive" orientation="horizontal" role="tabpanel" aria-labelledby="radix-_R_tda6j6_-trigger-401" tabindex="0"}
<figure
class="bg-fd-card rounded-xl shiki relative border shadow-sm not-prose overflow-hidden text-sm my-0"
dir="ltr" tabindex="-1">
<div
class="empty:hidden absolute top-3 right-2 z-2 backdrop-blur-lg rounded-lg text-fd-muted-foreground">
<img
src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNsaXBib2FyZCIgYXJpYS1oaWRkZW49InRydWUiPjxyZWN0IHdpZHRoPSI4IiBoZWlnaHQ9IjQiIHg9IjgiIHk9IjIiIHJ4PSIxIiByeT0iMSI+PC9yZWN0PjxwYXRoIGQ9Ik0xNiA0aDJhMiAyIDAgMCAxIDIgMnYxNGEyIDIgMCAwIDEtMiAySDZhMiAyIDAgMCAxLTItMlY2YTIgMiAwIDAgMSAyLTJoMiI+PC9wYXRoPjwvc3ZnPg=="
class="lucide lucide-clipboard" />
</div>
<div
class="text-[0.8125rem] py-3.5 overflow-auto max-h-[600px] fd-scroll-container focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-fd-ring"
role="region" tabindex="0"
style="--padding-right:calc(var(--spacing) * 8)">
<pre class="min-w-full w-max *:flex *:flex-col"><code>{  &quot;message&quot;: &quot;Unauthenticated.&quot;}</code></pre>
</div>
</figure>
:::

::: {#radix-_R_tda6j6_-content-409 .p-4 .text-[0.9375rem] .bg-fd-background .rounded-xl .outline-none .prose-no-margin .data-[state=inactive]:hidden .[&>figure:only-child]:-m-4 .[&>figure:only-child]:border-none state="inactive" orientation="horizontal" role="tabpanel" aria-labelledby="radix-_R_tda6j6_-trigger-409" tabindex="0"}
<figure
class="bg-fd-card rounded-xl shiki relative border shadow-sm not-prose overflow-hidden text-sm my-0"
dir="ltr" tabindex="-1">
<div
class="empty:hidden absolute top-3 right-2 z-2 backdrop-blur-lg rounded-lg text-fd-muted-foreground">
<img
src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNsaXBib2FyZCIgYXJpYS1oaWRkZW49InRydWUiPjxyZWN0IHdpZHRoPSI4IiBoZWlnaHQ9IjQiIHg9IjgiIHk9IjIiIHJ4PSIxIiByeT0iMSI+PC9yZWN0PjxwYXRoIGQ9Ik0xNiA0aDJhMiAyIDAgMCAxIDIgMnYxNGEyIDIgMCAwIDEtMiAySDZhMiAyIDAgMCAxLTItMlY2YTIgMiAwIDAgMSAyLTJoMiI+PC9wYXRoPjwvc3ZnPg=="
class="lucide lucide-clipboard" />
</div>
<div
class="text-[0.8125rem] py-3.5 overflow-auto max-h-[600px] fd-scroll-container focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-fd-ring"
role="region" tabindex="0"
style="--padding-right:calc(var(--spacing) * 8)">
<pre class="min-w-full w-max *:flex *:flex-col"><code>{  &quot;message&quot;: &quot;Domain conflicts detected. Use force_domain_override=true to proceed.&quot;,  &quot;warning&quot;: &quot;Using the same domain for multiple resources can cause routing conflicts and unpredictable behavior.&quot;,  &quot;conflicts&quot;: [    {      &quot;domain&quot;: &quot;example.com&quot;,      &quot;resource_name&quot;: &quot;My Application&quot;,      &quot;resource_uuid&quot;: &quot;abc123-def456&quot;,      &quot;resource_type&quot;: &quot;application&quot;,      &quot;message&quot;: &quot;Domain example.com is already in use by application &#39;My Application&#39;&quot;    }  ]}</code></pre>
</div>
</figure>
:::
:::
:::
:::
:::
:::
:::

::: {.@container .grid .gap-4 .grid-cols-2}
[](/docs/api-reference/authorization){.flex .flex-col .gap-2 .rounded-lg
.border .p-4 .text-sm .transition-colors .hover:bg-fd-accent/80
.hover:text-fd-accent-foreground .@max-lg:col-span-full}

::: {.inline-flex .items-center .gap-1.5 .font-medium}
![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tbGVmdCAtbXgtMSBzaXplLTQgc2hyaW5rLTAgcnRsOnJvdGF0ZS0xODAiIGFyaWEtaGlkZGVuPSJ0cnVlIj48cGF0aCBkPSJtMTUgMTgtNi02IDYtNiI+PC9wYXRoPjwvc3ZnPg==){.lucide
.lucide-chevron-left .-mx-1 .size-4 .shrink-0 .rtl:rotate-180}

[Authorization]{.fd-page-tree-item-name}
:::

Authenticate API requests to your Coolify instance using Bearer tokens
with scoped permissions, team isolation, and rate limiting.

[](/docs/api-reference/api/applications/create-dockerfile-application){.flex
.flex-col .gap-2 .rounded-lg .border .p-4 .text-sm .transition-colors
.hover:bg-fd-accent/80 .hover:text-fd-accent-foreground
.@max-lg:col-span-full .text-end}

::: {.inline-flex .items-center .gap-1.5 .font-medium .flex-row-reverse}
![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld2JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIGNsYXNzPSJsdWNpZGUgbHVjaWRlLWNoZXZyb24tcmlnaHQgLW14LTEgc2l6ZS00IHNocmluay0wIHJ0bDpyb3RhdGUtMTgwIiBhcmlhLWhpZGRlbj0idHJ1ZSI+PHBhdGggZD0ibTkgMTggNi02LTYtNiI+PC9wYXRoPjwvc3ZnPg==){.lucide
.lucide-chevron-right .-mx-1 .size-4 .shrink-0 .rtl:rotate-180}

[Create (Dockerfile without git) [POST]{.font-mono .font-medium
.text-blue-600 .dark:text-blue-400 .ms-auto .text-xs
.text-nowrap}]{.fd-page-tree-item-name}
:::

Create new application based on a simple Dockerfile (without git).
:::
:::
