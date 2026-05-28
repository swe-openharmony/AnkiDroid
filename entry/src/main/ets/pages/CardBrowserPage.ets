// Page: CardBrowserPage

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MockDataSource } from '../common/MockDataSource';

const TAG = 'CardBrowserPage';

interface CardRow {
  id: string;
  sortField: string;
  cardType: string;
  due: string;
  deck: string;
  status: string;   // New | Learning | Review | Suspended
}

interface CardsFile {
  cards: CardRow[];
  decks: string[];
  statuses: string[];
}

type SortKey = 'sortField' | 'cardType' | 'due' | 'deck';

@Entry
@Component
struct CardBrowserPage {
  @State private allCards: CardRow[] = [];
  @State private decks: string[] = ['All decks'];
  @State private statuses: string[] = ['All'];

  @State private sortKey: SortKey = 'sortField';
  @State private sortAsc: boolean = true;

  @State private searchActive: boolean = false;
  @State private searchText: string = '';

  @State private selectedDeck: string = 'All decks';
  @State private statusFilter: string = 'All';
  @State private deckPickerOpen: boolean = false;
  @State private overflowOpen: boolean = false;

  @State private selectionMode: boolean = false;
  @State private selectedIds: string[] = [];

  aboutToAppear(): void {
    // 场景一: entering the browser shows the full card set — reset any filter/search/
    // selection state from a prior visit (the page instance can be reused on re-entry).
    this.selectedDeck = 'All decks';
    this.statusFilter = 'All';
    this.searchActive = false;
    this.searchText = '';
    this.selectionMode = false;
    this.selectedIds = [];
    this.loadCards();
  }

  private async loadCards(): Promise<void> {
    try {
      const data = await MockDataSource.loadJson<CardsFile>(this, 'mock_cards.json');
      this.allCards = data.cards;
      if (data.decks && data.decks.length > 0) {
        this.decks = data.decks;
      }
      if (data.statuses && data.statuses.length > 0) {
        this.statuses = data.statuses;
      }
      hilog.info(0x0000, TAG, 'CardBrowser loaded %{public}d cards', this.allCards.length);
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
      this.allCards = [];
    }
  }

  // ── derived data ────────────────────────────────────────────────────
  private fieldOf(c: CardRow, key: SortKey): string {
    if (key === 'cardType') {
      return c.cardType;
    }
    if (key === 'due') {
      return c.due;
    }
    if (key === 'deck') {
      return c.deck;
    }
    return c.sortField;
  }

  private cmp(a: string, b: string): number {
    if (a < b) {
      return -1;
    }
    if (a > b) {
      return 1;
    }
    return 0;
  }

  private displayCards(): CardRow[] {
    const deck = this.selectedDeck;
    const status = this.statusFilter;
    const q = this.searchText.toLowerCase();
    const arr: CardRow[] = this.allCards.filter((c: CardRow) => {
      const deckOk: boolean = deck === 'All decks' || c.deck === deck || c.deck.startsWith(deck + '::');
      const statusOk: boolean = status === 'All' || c.status === status;
      const searchOk: boolean = q.length === 0 || c.sortField.toLowerCase().indexOf(q) >= 0;
      return deckOk && statusOk && searchOk;
    });
    const key = this.sortKey;
    const asc = this.sortAsc;
    arr.sort((x: CardRow, y: CardRow) => {
      const r = this.cmp(this.fieldOf(x, key), this.fieldOf(y, key));
      return asc ? r : -r;
    });
    return arr;
  }

  private subtitleText(): string {
    return `${this.displayCards().length} cards shown`;
  }

  // ── interactions ────────────────────────────────────────────────────
  private onHeaderClick(key: SortKey): void {
    if (this.sortKey === key) {
      this.sortAsc = !this.sortAsc;
    } else {
      this.sortKey = key;
      this.sortAsc = true;
    }
  }

  private onCardClick(card: CardRow): void {
    if (this.selectionMode) {
      this.toggleSelect(card.id);
      return;
    }
    router.pushUrl({ url: 'pages/NoteEditorPage', params: { cardId: card.id } });
  }

  private onCardLongPress(card: CardRow): void {
    if (!this.selectionMode) {
      this.selectionMode = true;
      this.selectedIds = [card.id];
    } else {
      this.toggleSelect(card.id);
    }
  }

  private toggleSelect(id: string): void {
    if (this.selectedIds.includes(id)) {
      this.selectedIds = this.selectedIds.filter((x: string) => x !== id);
    } else {
      this.selectedIds = this.selectedIds.concat([id]);
    }
  }

  private selectAll(): void {
    this.selectedIds = this.displayCards().map((c: CardRow) => c.id);
  }

  private exitSelection(): void {
    this.selectionMode = false;
    this.selectedIds = [];
  }

  private batchDelete(): void {
    const ids = this.selectedIds;
    this.allCards = this.allCards.filter((c: CardRow) => !ids.includes(c.id));
    this.exitSelection();
  }

  private batchSuspend(): void {
    const ids = this.selectedIds;
    this.allCards = this.allCards.map((c: CardRow) => {
      if (ids.includes(c.id)) {
        const nc: CardRow = {
          id: c.id, sortField: c.sortField, cardType: c.cardType,
          due: c.due, deck: c.deck, status: 'Suspended',
        };
        return nc;
      }
      return c;
    });
    this.exitSelection();
  }

  private selectDeck(d: string): void {
    this.selectedDeck = d;
    this.deckPickerOpen = false;
  }

  private selectStatus(s: string): void {
    this.statusFilter = s;
    this.overflowOpen = false;
  }

  // ── builders ────────────────────────────────────────────────────────
  @Builder
  private IconBtn(glyph: string, label: string, onTap: () => void) {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Text(glyph).fontSize(20).fontColor('#FFFFFF');
    }
    .width(48).height(48)
    .backgroundColor(Color.Transparent)
    .accessibilityText(label)
    .onClick(() => onTap());
  }

  @Builder
  private TopBar() {
    Row() {
      if (this.searchActive) {
        Text('←').fontSize(22).fontColor('#FFFFFF').width(48).height(48)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.searchActive = false; this.searchText = ''; });
        TextInput({ placeholder: 'Search cards', text: this.searchText })
          .layoutWeight(1)
          .backgroundColor('#FFFFFF')
          .margin({ right: 8 })
          .onChange((v: string) => { this.searchText = v; });
      } else {
        Column() {
          Row() {
            Text(this.selectedDeck)
              .fontSize(20).fontWeight(FontWeight.Medium).fontColor('#FFFFFF');
            Text(' ▾').fontSize(16).fontColor('#FFFFFF').margin({ left: 4 });
          }
          .alignItems(VerticalAlign.Center)
          .onClick(() => { this.deckPickerOpen = !this.deckPickerOpen; });
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 });

        this.IconBtn('+', 'Add', () => router.pushUrl({ url: 'pages/NoteEditorPage' }));
        this.IconBtn('🔍', 'Search', () => { this.searchActive = true; });
        this.IconBtn('⋮', 'More options', () => { this.overflowOpen = !this.overflowOpen; });
      }
    }
    .width('100%').height(72)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 4, right: 4 })
    .backgroundColor('#03A9F4');
  }

  @Builder
  private SelectionBar() {
    Row() {
      Text('✕').fontSize(22).fontColor('#FFFFFF').width(48).height(48)
        .textAlign(TextAlign.Center)
        .onClick(() => this.exitSelection());
      Text(`${this.selectedIds.length} selected`)
        .fontSize(20).fontColor('#FFFFFF').layoutWeight(1).margin({ left: 8 });
      Text('Select all').fontSize(14).fontColor('#FFFFFF').padding(10)
        .onClick(() => this.selectAll());
      Text('Suspend').fontSize(14).fontColor('#FFFFFF').padding(10)
        .onClick(() => this.batchSuspend());
      Text('Delete').fontSize(14).fontColor('#FFFFFF').padding(10)
        .onClick(() => this.batchDelete());
    }
    .width('100%').height(72)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 4, right: 4 })
    .backgroundColor('#0277BD');
  }

  @Builder
  private DropdownMenu(items: string[], onPick: (s: string) => void) {
    Column() {
      ForEach(items, (it: string) => {
        Text(it)
          .width('100%').fontSize(15).fontColor('#1F1F1F')
          .padding({ left: 20, right: 20, top: 14, bottom: 14 })
          .onClick(() => onPick(it));
      }, (it: string) => it);
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#E0E0E0' });
  }

  @Builder
  private HeaderCell(label: string, key: SortKey) {
    Row() {
      Text(label)
        .fontSize(14).fontColor('#1F1F1F')
        .fontWeight(this.sortKey === key ? FontWeight.Medium : FontWeight.Regular);
      if (this.sortKey === key) {
        // ▲/▼ (not ▴/▾) to avoid colliding with the deck-title dropdown caret ' ▾'.
        Text(this.sortAsc ? ' ▲' : ' ▼').fontSize(12).fontColor('#5F6368').margin({ left: 2 });
      }
    }
    .layoutWeight(1).height(56).padding({ left: 12, right: 8 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.onHeaderClick(key));
  }

  @Builder
  private HeaderRow() {
    Row() {
      this.HeaderCell('Sort Field', 'sortField');
      this.HeaderCell('Card Type', 'cardType');
      this.HeaderCell('Due', 'due');
      this.HeaderCell('Deck', 'deck');
    }
    .width('100%').alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#E0E0E0' });
  }

  @Builder
  private CardItem(card: CardRow) {
    Row() {
      Text(card.sortField).layoutWeight(1).fontSize(14).fontColor('#1F1F1F')
        .padding({ left: 12, right: 8, top: 12, bottom: 12 });
      Text(card.cardType).layoutWeight(1).fontSize(14).fontColor('#1F1F1F')
        .padding({ left: 8, right: 8, top: 12, bottom: 12 });
      Text(card.due).layoutWeight(1).fontSize(14).fontColor('#1F1F1F')
        .padding({ left: 8, right: 8, top: 12, bottom: 12 });
      Text(card.deck).layoutWeight(1).fontSize(14).fontColor('#1F1F1F')
        .padding({ left: 8, right: 12, top: 12, bottom: 12 });
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .backgroundColor(this.selectedIds.includes(card.id) ? '#E3F2FD' : '#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: '#EEEEEE' })
    .gesture(LongPressGesture({ repeat: false }).onAction(() => this.onCardLongPress(card)))
    .onClick(() => this.onCardClick(card));
  }

  build() {
    Column() {
      if (this.selectionMode) {
        this.SelectionBar();
      } else {
        this.TopBar();
      }

      // Always-visible result count (spec 场景一/三: "N cards shown", updates
      // with search/filter). Kept out of the title row so it shows during search.
      if (!this.selectionMode) {
        Row() {
          Text(this.subtitleText())
            .fontSize(13).fontColor('#5F6368')
            .padding({ left: 16, right: 16, top: 6, bottom: 6 });
        }
        .width('100%').backgroundColor('#FFFFFF');
      }

      // Inline dropdowns (below the bar) — deck picker / status overflow.
      if (this.deckPickerOpen && !this.selectionMode) {
        this.DropdownMenu(this.decks, (s: string) => this.selectDeck(s));
      }
      if (this.overflowOpen && !this.selectionMode) {
        this.DropdownMenu(this.statuses, (s: string) => this.selectStatus(s));
      }

      this.HeaderRow();

      List() {
        ForEach(this.displayCards(), (card: CardRow) => {
          ListItem() {
            this.CardItem(card);
          }
        }, (card: CardRow) => card.id);
      }
      .layoutWeight(1).width('100%');
    }
    .width('100%').height('100%')
    .backgroundColor('#FFFFFF');
  }
}
