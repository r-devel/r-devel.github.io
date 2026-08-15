# Axe-core navbar landmark warning with Quarto TOC

## Summary

On a Quarto website, axe-core reports:

> Moderate · Best Practice: Ensure landmarks are unique
> Landmarks should have a unique role or role/label/title (i.e. accessible name) combination
> .navbar

This happens when both the **navbar** and the **page TOC** are enabled.

## Minimal reproducible setup

`_quarto.yml`:

```yaml
project:
  type: website

website:
  title: "Test site"
  navbar:
    aria-label: "Primary site navigation"
    search: true

format:
  html:
    toc: true
    axe:
      output: document
```

Index page (`index.qmd`):

```yaml
---
title: "Home"
---

## Section 1

Text.

## Section 2

Text.
```

## Rendered landmarks (relevant parts)

Header/navbar:

```html
<header id="quarto-header" class="headroom fixed-top">
  <nav class="navbar navbar-expand-lg" data-bs-theme="dark" aria-label="Primary site navigation">
    ...
  </nav>
</header>
```

Margin TOC:

```html
<div id="quarto-margin-sidebar" class="sidebar margin-sidebar">
  <nav id="TOC" role="doc-toc" class="toc-active">
    <h2 id="toc-title">On this page</h2>
    <ul>
      <li><a href="#section-1" class="nav-link" data-scroll-target="#section-1">Section 1</a></li>
      <li><a href="#section-2" class="nav-link" data-scroll-target="#section-2">Section 2</a></li>
    </ul>
  </nav>
</div>
```

## Behaviour

- With `format.html.toc: true`, axe-core reports the non-unique landmark warning on `.navbar`.
- Setting `format.html.toc: false` removes the warning.
- Adding `navbar.aria-label: "Primary site navigation"` does **not** remove the warning.

## Interpretation / question

It appears that the combination of:

- `<nav class="navbar ...">` (main navigation landmark), and
- `<nav id="TOC" role="doc-toc" ...>` (TOC landmark)

is causing axe-core’s "Ensure landmarks are unique" rule to fire.

Question for Quarto:

- Is this landmark structure (navbar + `role="doc-toc"` TOC) intended to satisfy axe-core’s uniqueness rule, or is there an adjustment needed (e.g. roles/labels) so that axe-core no longer flags `.navbar` when `toc: true` is used on websites?
