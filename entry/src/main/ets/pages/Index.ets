// ====================================================================
// Page: Index (AnkiDroid L0 Home — DeckPicker)
// Android baseline: D:/OH-Appforge/_doc_screenshots_v2/AnkiDroid/L0_home.png
// Layout contract:
//   - Top app bar (cyan): hamburger + "AnkiDroid" + subtitle "1 card due"
//     + sync icon (with red ! badge) + overflow ⋮ + Browse (book) icon
//   - Deck list: light-grey row "Default" with counts "1 0 0" on the right
//   - Bottom FAB '+' (blue) + footer "Studied 0 cards in 0 seconds today"
// Navigation:
//   - Top "Browse" icon tap → CardBrowserPage
//   - FAB '+' tap → NoteEditorPage
// ====================================================================

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MockDataSource } from '../common/MockDataSource';

const TAG = 'AnkiDroidIndex';

interface DeckRow {
  name: string;
  newCount: number;
  learnCount: number;
  reviewCount: number;
}

interface DecksFile {
  decks: DeckRow[];
  cardsDue: number;
  studiedToday: string;
}

@Entry
@Component
struct Index {
  @State private decks: DeckRow[] = [];
  @State private cardsDue: number = 1;
  @State private studiedToday: string = 'Studied 0 cards in 0 seconds today (0s/card)';

  aboutToAppear(): void {
    hilog.info(0x0000, TAG, 'AnkiDroid L0 home mounted');
    this.loadDecks();
  }

  private async loadDecks(): Promise<void> {
    try {
      const data = await MockDataSource.loadJson<DecksFile>(this, 'mock_home.json');
      this.decks = data.decks;
      this.cardsDue = data.cardsDue;
      this.studiedToday = data.studiedToday;
      hilog.info(0x0000, TAG, 'loaded %{public}d decks', this.decks.length);
    } catch (e) {
      hilog.error(0x0000, TAG, 'load mock_home failed: %{public}s', String(e));
      this.decks = [{ name: 'Default', newCount: 1, learnCount: 0, reviewCount: 0 }];
    }
  }

  @Builder
  private TopBar() {
    Row() {
      Text('≡').fontSize(24).fontColor('#FFFFFF').width(44).height(44).textAlign(TextAlign.Center)
        .onClick(() => console.info('TODO: drawer'));
      Column() {
        Text('AnkiDroid').fontSize(20).fontWeight(FontWeight.Medium).fontColor('#FFFFFF');
        Text(`${this.cardsDue} card due`).fontSize(13).fontColor('#FFFFFF');
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 4 });

      // Browse (book) icon → CardBrowserPage
      Text('📖').fontSize(20).fontColor('#FFFFFF').width(44).height(44).textAlign(TextAlign.Center)
        .accessibilityText('Browse cards')
        .onClick(() => {
          hilog.info(0x0000, TAG, 'browse → CardBrowserPage');
          router.pushUrl({ url: 'pages/CardBrowserPage' });
        });

      // Sync icon with badge
      Stack() {
        Text('↻').fontSize(20).fontColor('#FFFFFF');
        Text('!').fontSize(10).fontColor('#FFFFFF')
          .width(14).height(14).textAlign(TextAlign.Center)
          .backgroundColor('#FF5722').borderRadius(7)
          .position({ x: 22, y: -2 });
      }
      .width(44).height(44)
      .onClick(() => console.info('TODO: sync'));

      Text('⋮').fontSize(22).fontColor('#FFFFFF').width(40).height(44).textAlign(TextAlign.Center)
        .onClick(() => console.info('TODO: overflow'));
    }
    .width('100%').height(64)
    .padding({ right: 8 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#03A9F4');
  }

  @Builder
  private DeckRowItem(deck: DeckRow) {
    Row() {
      Text(deck.name)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F1F1F')
        .layoutWeight(1)
        .margin({ left: 16 })
        .onClick(() => {
          hilog.info(0x0000, TAG, 'deck tap → study %{public}s', deck.name);
          console.info(`TODO: study deck ${deck.name}`);
        });
      // counts area — Android maps this to "Open the deck overview page"
      Row() {
        Text(`${deck.newCount}`).fontSize(15).fontColor('#3A5BCF').margin({ right: 12 });
        Text(`${deck.learnCount}`).fontSize(15).fontColor('#AAAAAA').margin({ right: 12 });
        Text(`${deck.reviewCount}`).fontSize(15).fontColor('#AAAAAA').margin({ right: 16 });
      }
      .alignItems(VerticalAlign.Center)
      .accessibilityText('Open the deck overview page')
      .onClick(() => {
        hilog.info(0x0000, TAG, 'counts tap → overview %{public}s', deck.name);
        console.info(`TODO: overview ${deck.name}`);
      });
    }
    .width('100%').height(52)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#E5E5E5')
    .gesture(
      LongPressGesture().onAction(() => {
        hilog.info(0x0000, TAG, 'deck long-press %{public}s', deck.name);
        console.info(`TODO: deck context menu ${deck.name}`);
      })
    );
  }

  @Builder
  private Fab() {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      Text('+').fontSize(28).fontColor('#FFFFFF');
    }
    .width(64).height(64)
    .borderRadius(18)
    .backgroundColor('#03A9F4')
    .position({ x: '100%', y: '100%' })
    .markAnchor({ x: 80, y: 120 })
    .accessibilityText('Add note')
    .onClick(() => {
      hilog.info(0x0000, TAG, 'FAB → NoteEditorPage');
      router.pushUrl({ url: 'pages/NoteEditorPage' });
    });
  }

  build() {
    Stack() {
      Column() {
        this.TopBar();
        // Deck list
        List() {
          ForEach(this.decks, (d: DeckRow) => {
            ListItem() { this.DeckRowItem(d); }
          }, (d: DeckRow) => d.name);
        }
        .layoutWeight(1)
        .width('100%');

        // Footer
        Text(this.studiedToday)
          .fontSize(13)
          .fontColor('#444444')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 16 });
      }
      .width('100%').height('100%');

      this.Fab();
    }
    .width('100%').height('100%')
    .backgroundColor('#FFFFFF');
  }
}
