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
}

interface CardsFile {
  cards: CardRow[];
}

type SortKey = 'sortField' | 'cardType' | 'due' | 'deck';

@Entry
@Component
struct CardBrowserPage {
  @State private deckName: string = 'Default';
  @State private subtitle: string = '4 cards shown';
  @State private sortKey: SortKey = 'sortField';
  @State private sortAsc: boolean = true;

  @State private cards: CardRow[] = [];

  aboutToAppear(): void {
    this.loadCards();
  }

  private async loadCards(): Promise<void> {
    try {
      const data = await MockDataSource.loadJson<CardsFile>(this, 'mock_cards.json');
      this.cards = data.cards;
      this.subtitle = `${this.cards.length} cards shown`;
      hilog.info(0x0000, TAG, 'CardBrowser loaded %{public}d cards from rawfile', this.cards.length);
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
      this.cards = [];
    }
  }

  private onHeaderClick(key: SortKey): void {
    if (this.sortKey === key) {
      this.sortAsc = !this.sortAsc;
    } else {
      this.sortKey = key;
      this.sortAsc = true;
    }
    hilog.info(0x0000, TAG, 'sort key=%{public}s asc=%{public}s', key, String(this.sortAsc));
  }

  private onCardClick(card: CardRow): void {
    hilog.info(0x0000, TAG, 'open card %{public}s', card.id);
    router.pushUrl({ url: 'pages/NoteEditorPage', params: { cardId: card.id } });
  }

  private onAddClick(): void {
    router.pushUrl({ url: 'pages/NoteEditorPage' });
  }

  private onSearchClick(): void {
    hilog.info(0x0000, TAG, 'TODO open search');
  }

  private onMoreClick(): void {
    hilog.info(0x0000, TAG, 'TODO overflow menu');
  }

  @Builder
  private TopBar() {
    Row() {
      // Hamburger drawer toggle
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('☰').fontSize(22).fontColor('#FFFFFF');
      }
      .width(48).height(48)
      .backgroundColor(Color.Transparent)
      .accessibilityText('Open drawer')
      .margin({ left: 4 });

      // Deck name + subtitle stack
      Column() {
        Row() {
          Text(this.deckName)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF');
          Text(' ▾')   // small dropdown caret
            .fontSize(16)
            .fontColor('#FFFFFF')
            .margin({ left: 4 });
        }
        .alignItems(VerticalAlign.Center);

        Text(this.subtitle)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .opacity(0.9)
          .margin({ top: 2 });
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 8 });

      // Add (+) icon
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('+').fontSize(26).fontColor('#FFFFFF').fontWeight(FontWeight.Medium);
      }
      .width(48).height(48)
      .backgroundColor(Color.Transparent)
      .accessibilityText('Add')
      .onClick(() => this.onAddClick());

      // Search icon
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('🔍').fontSize(20).fontColor('#FFFFFF');  // 🔍
      }
      .width(48).height(48)
      .backgroundColor(Color.Transparent)
      .accessibilityText('Search')
      .onClick(() => this.onSearchClick());

      // Overflow (⋮)
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('⋮').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold);
      }
      .width(48).height(48)
      .backgroundColor(Color.Transparent)
      .accessibilityText('More options')
      .margin({ right: 4 })
      .onClick(() => this.onMoreClick());
    }
    .width('100%')
    .height(72)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#03A9F4');
  }

  @Builder
  private HeaderCell(label: string, key: SortKey) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#1F1F1F')
        .fontWeight(this.sortKey === key ? FontWeight.Medium : FontWeight.Regular);
      if (this.sortKey === key) {
        Text(this.sortAsc ? ' ▴' : ' ▾')
          .fontSize(12)
          .fontColor('#5F6368')
          .margin({ left: 2 });
      }
    }
    .layoutWeight(1)
    .height(56)
    .padding({ left: 12, right: 8 })
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
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#E0E0E0' });
  }

  @Builder
  private CardItem(card: CardRow) {
    Row() {
      Text(card.sortField)
        .layoutWeight(1)
        .fontSize(14)
        .fontColor('#1F1F1F')
        .padding({ left: 12, right: 8, top: 12, bottom: 12 });
      Text(card.cardType)
        .layoutWeight(1)
        .fontSize(14)
        .fontColor('#1F1F1F')
        .padding({ left: 8, right: 8, top: 12, bottom: 12 });
      Text(card.due)
        .layoutWeight(1)
        .fontSize(14)
        .fontColor('#1F1F1F')
        .padding({ left: 8, right: 8, top: 12, bottom: 12 });
      Text(card.deck)
        .layoutWeight(1)
        .fontSize(14)
        .fontColor('#1F1F1F')
        .padding({ left: 8, right: 12, top: 12, bottom: 12 });
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .border({ width: { bottom: 0.5 }, color: '#EEEEEE' })
    .onClick(() => this.onCardClick(card));
  }

  build() {
    Column() {
      this.TopBar();
      this.HeaderRow();

      List() {
        ForEach(this.cards, (card: CardRow) => {
          ListItem() {
            this.CardItem(card);
          }
        }, (card: CardRow) => card.id);
      }
      .layoutWeight(1)
      .width('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}
