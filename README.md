# Theming Made Easy: Introducing brand.yml

**Speaker:** Garrick Aden-Buie

posit::conf(2025)

<https://reg.conf.posit.co/flow/posit/positconf25/attendee-portal/page/sessioncatalog/session/1745351601272001atTE>

## Abstract

brand.yml is an exciting new project from Posit that radically simplifies theming. Every data science tool supports some form of theme and appearance customization, but each app framework, output format, or visualization tool requires its own special syntax for theming.

The goal of brand.yml is to create a portable and unified interface for brand-related theming that can be used anywhere that data science artifacts are produced. As a collaboration between the Shiny and Quarto teams, brand.yml provides a single interface to setting baseline themes in reports and apps across the R and Python ecosystems.

In this talk, I’ll introduce brand.yml and showcase the many ways that brand.yml can bring consistent styles to your data science outputs.

## Impact statement

If you were to do X1, X2, X3, you'll be able to do Y with Z impact.

X1: translate your brand guidelines into a simple YAML file
X3: collect all your logos and typography
X3: just once
Y: create reports, slides, websites that match your brand's styles
Z: help your materials have more impact

## Story

A data scientist needs to present something to their stakeholders, so they build an app. They know this is an important demo, so they spend a few days making the app look great. The demo looks awesome and goes really well, gets shared throughout the org, etc, big success, new budget streams and more 💰.

And then they say: since we're sharing this a lot, can we have a PDF summary? Meme (two buttons, sweating: share ugly report; learn LaTeX).

Enter: brand.yml

## Outline

**Chapter 1: The Power of Aesthetic Design in Shiny**

- Story: How a polished Shiny demo led to business success
- The role of visual appeal and branding in communication
- The "aesthetic usability effect" and why it matters

**Chapter 2: Evolving Toward Design Systems**

- Introduction to design systems and brand assets
- Visual examples: Pulse Mobile brand assets and design systems in practice
- Motivation for standardized theming

**Chapter 3: brand.yml — Structure and Usage**

- Anatomy of a `_brand.yml` file: meta, color, typography, logo
- Step-by-step YAML examples for branding attributes

**Chapter 4: Integrating brand.yml in reports, apps and websites**

- `brand.yml` in Quarto
- `brand.yml` in Shiny apps
- `brand.yml` in other areas and beyond
