# Shared-21: AddBillScreen UI Polish & Redesign

**Layer:** Presentation (AddBillScreen UI Polish & Redesign)  
**Task ID:** t21  
**Priority:** High  
**Status:** In Progress  

---

## 1. Overview
Redesign and polish `AddBillScreen` based on the CEO's mockup and feedback. Refine typography, spacing, cards, color integration from selected category, smooth animations, and visual hierarchy while strictly preserving all functionality from Shared-18, Shared-19, and Shared-20.

---

## 2. Acceptance Criteria

1. **Header Polish:**
   - Refined typography (font size, weight), proper spacing.
   - Close button with ripple effect (`IconButton` with `Key('closeButton')` or standard back button).
   - Subtle shadow or divider below header (`Divider(height: 1, thickness: 1)`).

2. **Tab Selector Refinement:**
   - Tab bar with Expense, Income, Transfer (`Key('transactionTypeTabs')`).
   - Smooth animation on tab switch.
   - Visual feedback with highlight / underline effect and consistent padding.

3. **Title Section Layout (CEO Update):**
   - **LEFT:** Circular badge with category icon on colored background from category brand color (`Key('selectedCategoryIconBadge')`).
   - **CENTER:** Title input field (`Key('titleField')`) auto-filled with category name if user hasn't typed custom title yet (Shared-20 logic).
   - **RIGHT:** Camera icon button (`Key('cameraTitleButton')` / `takeCameraButton`) + Clear (X) button (`Key('clearTitleButton')`).

4. **Image Preview:**
   - Larger rounded corners (`borderRadius: BorderRadius.circular(16)`).
   - Subtle elevation / shadow.
   - Better aspect ratio display (square / 16:9).
   - Remove button (`Key('removeImageButton')`) positioned at the bottom-right corner.

5. **Amount Section:**
   - Better visual separation with clear label.
   - Currency dropdown styled as compact pill (`Key('currencyDropdown')`).
   - Amount input with proper text alignment (right-aligned) and formatted display.

6. **Paid By & When Section:**
   - Two-column layout with equal width cards (`Row` with two `Expanded` cards).
   - Column 1: Paid By / Payer card with dropdown/input styling (`Key('payerField')`).
   - Column 2: When / Date picker card with calendar icon (`Key('datePickerButton')`).

7. **Split Section:**
   - Card-based display for each person (Name + Avatar / Initials + Checkbox + Amount).
   - Checkboxes with smooth animations (`Checkbox` / `InkWell`).
   - Amounts displayed with currency symbol (`Key('realtimeSplitText')`).
   - Better visual hierarchy with participant count and clear separation.

8. **Color Integration:**
   - Category color applied as accent color throughout form (header / badge, tab indicator, active borders, card highlights).
   - Consistent brand colors matching 12 categories.

9. **Spacing & Padding:**
   - Consistent grid-based spacing (8px increments: 8, 16, 24).
   - Adequate whitespace and hierarchy.

10. **Interactive Feedback:**
    - Ripple effects on buttons (`InkWell` / `ButtonStyle`).
    - Smooth focus transitions on inputs.
    - Loading states and submit feedback.

11. **Dark Mode Refinement:**
    - Proper contrast ratios.
    - Refined surface background colors (not pure black #000, but dark theme surface #1E1E1E / #2C2C2C).
    - Consistent component theming.

12. **Comprehensive Tests:**
    - 80+ test cases covering layout metrics, spacing, animations, colors, dark mode, accessibility, and backwards compatibility.
