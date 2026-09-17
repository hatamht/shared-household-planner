# Feature Specification: Shared-37 Smart Split Modes (Percent, Shares, Custom)

## 1. Overview
Smart Split Modes extends the Split Bills module in Shared Household Planner to support four distinct ways of splitting expenses among participants:
1. **Equal**: Total amount divided equally among all participants.
2. **By Percentage**: Each participant pays a specified percentage of the total amount (e.g. 30% / 40% / 30%), summing to 100%.
3. **By Shares**: Each participant is assigned a number of shares (e.g. child = 1 share, adult = 2 shares, 3:2:1 ratio). Total shares must be > 0.
4. **Custom Amount**: Each participant pays an exact specified amount, summing to the total bill amount.

Additionally, users can:
- Switch modes effortlessly via radio buttons on \`AddBillScreen\`.
- View dynamic real-time calculation breakdown for each participant as amounts/percentages/shares change.
- Benefit from strict client-side validation preventing unbalanced splits.
- View a detailed breakdown in \`BillDetailScreen\` accessible from \`BillCard\`.
- Save a split mode as the default for a category or person.

---

## 2. Acceptance Criteria
- [x] **Split Mode 1: Equal** - everyone pays same (\`amount / N\`).
- [x] **Split Mode 2: By Percentage** - specify percentages per participant; sum must equal 100%.
- [x] **Split Mode 3: By Shares** - specify shares per participant (e.g. 2 shares, 1 share); calculated proportionally.
- [x] **Split Mode 4: Custom Amount** - specify exact amounts per person; sum must equal total bill amount.
- [x] **UI**: Radio buttons to switch modes on \`AddBillScreen\` (\`Key('splitModeRadioGroup')\`, \`Key('splitModeRadio_equal')\`, etc.).
- [x] **Validation**: percentages sum to 100%, shares > 0, custom amounts equal total bill amount.
- [x] **Display split breakdown in bill detail view**: \`BillDetailScreen\` shows participant list, percentages/shares, and amounts.
- [x] **Save split mode as default for category or person**: \`DefaultSplitModeService\` persists preferences and auto-selects default mode.
- [x] **Tests: 100+**: comprehensive unit and widget tests covering calculations, validations, persistence, UI, and edge cases.

---

## 3. Architecture & Data Model

### 3.1 Entities
- \`SplitMode\`: enum \`{ equal, percentage, shares, custom }\` with string mapping and localization helpers.
- \`BillParticipant\`:
  - \`participantId: String\`
  - \`name: String\`
  - \`amount: double\`
  - \`percentage: double?\`
  - \`shares: double?\`
- \`Bill\`:
  - Existing fields preserved for backward compatibility.
  - \`splitMode: String\` (default: \`'equal'\`).
  - Helper \`splitModeEnum\` and \`getParticipantBreakdown(BillParticipant)\`.

### 3.2 Calculation & Validation Service
- \`SmartSplitCalculator\`:
  - \`calculateEqual(amount, participants)\`
  - \`calculatePercentage(amount, percentages)\`
  - \`calculateShares(amount, shares)\`
  - \`calculateCustom(amount, amounts)\`
  - Validation routines with descriptive errors.

### 3.3 Default Split Mode Service
- \`DefaultSplitModeService\`:
  - Stores default split modes per category ID and/or person name.
  - Pluggable storage with in-memory caching.

---

## 4. UI Components
- **AddBillScreen**:
  - Split Mode Radio Group (\`Key('splitModeRadioGroup')\`).
  - Real-time participant input rows (\`Key('percentageInput_${name}')\`, \`Key('sharesInput_${name}')\`, \`Key('customAmountInput_${name}')\`).
  - Real-time calculated amounts (\`Key('calculatedAmount_${name}')\`).
  - Total percentage indicator (\`Key('totalPercentageText')\`), total shares indicator (\`Key('totalSharesText')\`), remaining amount indicator (\`Key('remainingAmountText')\`).
  - "Save as default for category" checkbox (\`Key('saveDefaultSplitModeCheckbox')\`).
- **BillDetailScreen**:
  - Full details view with participant breakdown list (\`Key('billDetailBreakdown')\`).
  - Participant item with name, badge, and amount (\`Key('breakdownParticipantName_${name}')\`, \`Key('breakdownParticipantAmount_${name}')\`).
- **BillCard**:
  - Tapping opens \`BillDetailScreen\`.
  - Split mode indicator chip (\`Key('splitModeChip_${bill.id}')\`).
