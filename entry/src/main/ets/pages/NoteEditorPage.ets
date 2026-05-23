// Page: NoteEditorPage

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MockDataSource } from '../common/MockDataSource';

const TAG = 'NoteEditorPage';

interface FormatButton {
  glyph: string;
  label: string;
  fontWeight: FontWeight;
  italic: boolean;
  underline: boolean;
}

// JSON-side shape: fontWeight is a string ("bold"/"regular") so we map after load.
interface FormatButtonRaw {
  glyph: string;
  label: string;
  fontWeight: string;
  italic: boolean;
  underline: boolean;
}

interface NoteEditorFile {
  noteTypes: string[];
  deckNames: string[];
  formatButtons: FormatButtonRaw[];
}

@Entry
@Component
struct NoteEditorPage {
  @State private noteType: string = 'Cloze';
  @State private deckName: string = 'Default';
  @State private frontText: string = '';
  @State private backExtraText: string = '';
  @State private tags: string = '';
  @State private cardsLabel: string = 'Cloze';

  @State private noteTypes: string[] = [];
  @State private deckNames: string[] = [];

  @State private formatButtons: FormatButton[] = [];

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string> | undefined;
    if (params && params.cardId) {
      hilog.info(0x0000, TAG, 'edit existing card %{public}s (TODO load)', params.cardId);
    }
    this.loadNoteEditor();
  }

  private async loadNoteEditor(): Promise<void> {
    try {
      const data = await MockDataSource.loadJson<NoteEditorFile>(this, 'mock_note_editor.json');
      this.noteTypes = data.noteTypes;
      this.deckNames = data.deckNames;
      this.formatButtons = data.formatButtons.map((b: FormatButtonRaw): FormatButton => {
        return {
          glyph: b.glyph,
          label: b.label,
          fontWeight: b.fontWeight === 'bold' ? FontWeight.Bold : FontWeight.Regular,
          italic: b.italic,
          underline: b.underline
        } as FormatButton;
      });
      hilog.info(0x0000, TAG, 'loaded note editor mock: %{public}d types, %{public}d decks, %{public}d format buttons',
        this.noteTypes.length, this.deckNames.length, this.formatButtons.length);
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
      this.noteTypes = [];
      this.deckNames = [];
      this.formatButtons = [];
    }
  }

  private onSaveClick(): void {
    hilog.info(0x0000, TAG, 'save note type=%{public}s deck=%{public}s',
      this.noteType, this.deckName);
    router.back();
  }

  private onPreviewClick(): void {
    hilog.info(0x0000, TAG, 'TODO open card preview');
  }

  private onMoreClick(): void {
    hilog.info(0x0000, TAG, 'TODO overflow menu');
  }

  @Builder
  private TopBar() {
    Row() {
      // Back arrow
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('←').fontSize(22).fontColor('#FFFFFF');
      }
      .width(48).height(48)
      .backgroundColor(Color.Transparent)
      .accessibilityText('Navigate up')
      .margin({ left: 4 })
      .onClick(() => router.back());

      Text('Add')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .layoutWeight(1)
        .margin({ left: 8 });

      // ✓ Save
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('✓').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold);
      }
      .width(48).height(48)
      .backgroundColor(Color.Transparent)
      .accessibilityText('Save')
      .onClick(() => this.onSaveClick());

      // 👁 Preview
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('👁').fontSize(18).fontColor('#FFFFFF');
      }
      .width(48).height(48)
      .backgroundColor(Color.Transparent)
      .accessibilityText('Preview')
      .onClick(() => this.onPreviewClick());

      // ⋮ overflow
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
    .height(64)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#03A9F4');
  }

  @Builder
  private SpinnerRow(label: string, value: string, onTap: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F1F1F')
        .width(72)
        .padding({ left: 16 });

      Text(value)
        .fontSize(15)
        .fontColor('#1F1F1F')
        .layoutWeight(1)
        .padding({ left: 8 });

      Text('▾')   // ▾
        .fontSize(14)
        .fontColor('#5F6368')
        .margin({ right: 16 });
    }
    .width('100%')
    .height(56)
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })
    .onClick(() => onTap());
  }

  @Builder
  private FieldBlock(label: string, text: string, onChange: (v: string) => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(15)
          .fontColor('#1F1F1F')
          .layoutWeight(1)
          .padding({ left: 16 })
          .onClick(() => console.info(`TODO: focus field ${label}`));

        // 📌 sticky toggle
        Text('📌')
          .fontSize(16).fontColor('#9AA0A6')
          .width(40).height(40)
          .textAlign(TextAlign.Center)
          .accessibilityText(`Make field ${label} sticky`)
          .onClick(() => console.info(`TODO: toggle sticky ${label}`));

        // 📎 media attach
        Text('📎')
          .fontSize(16).fontColor('#5F6368')
          .width(40).height(40)
          .textAlign(TextAlign.Center)
          .accessibilityText(`Attach multimedia to ${label}`)
          .onClick(() => console.info(`TODO: attach multimedia to ${label}`));

        // ▲ expand/collapse
        Text('▲')
          .fontSize(13).fontColor('#5F6368')
          .width(40).height(40)
          .textAlign(TextAlign.Center)
          .margin({ right: 8 })
          .onClick(() => console.info(`TODO: expand field ${label}`));
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ top: 8 });

      TextArea({ placeholder: '', text: text })
        .width('100%')
        .height(80)
        .fontSize(15)
        .fontColor('#1F1F1F')
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .padding({ left: 16, right: 16, top: 4, bottom: 8 })
        .onChange((v: string) => onChange(v))
        .onClick(() => console.info(`TODO: focus textarea ${label}`));
    }
    .width('100%')
    .border({ width: { bottom: 0.5 }, color: '#E0E0E0' });
  }

  @Builder
  private TagsRow() {
    Row() {
      Text('Tags: ')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F1F1F')
        .padding({ left: 16 });
      Text(this.tags.length > 0 ? this.tags : '')
        .fontSize(14)
        .fontColor('#5F6368')
        .layoutWeight(1);
    }
    .width('100%')
    .height(56)
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })
    .onClick(() => console.info('TODO: open tag editor'));
  }

  @Builder
  private CardsRow() {
    Row() {
      Text(`Cards: ${this.cardsLabel}`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F1F1F')
        .padding({ left: 16 });
      Blank().layoutWeight(1);
    }
    .width('100%')
    .height(56)
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })
    .onClick(() => console.info('TODO: open cards template editor'));
  }

  @Builder
  private FormatToolbar() {
    Scroll() {
      Row() {
        // Bold
        Text('B').fontSize(18).fontColor('#1F1F1F').fontWeight(FontWeight.Bold)
          .width(56).height(48).textAlign(TextAlign.Center)
          .accessibilityText('Bold')
          .onClick(() => console.info('TODO: format bold'));
        // Italic
        Text('I').fontSize(18).fontColor('#1F1F1F').fontStyle(FontStyle.Italic)
          .width(56).height(48).textAlign(TextAlign.Center)
          .accessibilityText('Italic')
          .onClick(() => console.info('TODO: format italic'));
        // Underline
        Text('U').fontSize(18).fontColor('#1F1F1F')
          .decoration({ type: TextDecorationType.Underline })
          .width(56).height(48).textAlign(TextAlign.Center)
          .accessibilityText('Underline')
          .onClick(() => console.info('TODO: format underline'));
        // Horizontal rule
        Text('—').fontSize(18).fontColor('#1F1F1F')
          .width(56).height(48).textAlign(TextAlign.Center)
          .accessibilityText('Horizontal rule')
          .onClick(() => console.info('TODO: insert horizontal rule'));
        // Heading
        Text('T').fontSize(18).fontColor('#1F1F1F').fontWeight(FontWeight.Bold)
          .width(56).height(48).textAlign(TextAlign.Center)
          .accessibilityText('Heading')
          .onClick(() => console.info('TODO: insert heading'));
        // Font size
        Text('Tt').fontSize(18).fontColor('#1F1F1F')
          .width(56).height(48).textAlign(TextAlign.Center)
          .accessibilityText('Font size')
          .onClick(() => console.info('TODO: open font size picker'));
        // MathJax
        Text('Σ').fontSize(18).fontColor('#1F1F1F')
          .width(56).height(48).textAlign(TextAlign.Center)
          .accessibilityText('MathJax')
          .onClick(() => console.info('TODO: insert MathJax'));
        // Cloze new
        Text('[..+]').fontSize(18).fontColor('#1F1F1F')
          .width(56).height(48).textAlign(TextAlign.Center)
          .accessibilityText('Cloze new')
          .onClick(() => console.info('TODO: insert new cloze'));
        // Cloze same
        Text('[..]').fontSize(18).fontColor('#1F1F1F')
          .width(56).height(48).textAlign(TextAlign.Center)
          .accessibilityText('Cloze same')
          .onClick(() => console.info('TODO: insert same-number cloze'));
      }
      .height(48);
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(48)
    .backgroundColor('#F5F5F5');
  }

  build() {
    Column() {
      this.TopBar();

      Scroll() {
        Column() {
          // Type spinner row (inline so each control gets its own click target)
          Row() {
            Text('Type:').fontSize(15).fontWeight(FontWeight.Bold).fontColor('#1F1F1F').width(72).padding({ left: 16 })
              .onClick(() => console.info('TODO: open note type picker (label tap)'));
            Text(this.noteType).fontSize(15).fontColor('#1F1F1F').layoutWeight(1).padding({ left: 8 })
              .onClick(() => {
                const idx: number = this.noteTypes.indexOf(this.noteType);
                this.noteType = this.noteTypes[(idx + 1) % this.noteTypes.length];
              });
            Text('▾').fontSize(14).fontColor('#5F6368').margin({ right: 16 })
              .onClick(() => console.info('TODO: open note type spinner'));
          }
          .width('100%').height(56).alignItems(VerticalAlign.Center)
          .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })
          .onClick(() => {
            const idx: number = this.noteTypes.indexOf(this.noteType);
            this.noteType = this.noteTypes[(idx + 1) % this.noteTypes.length];
          });

          // Deck spinner row
          Row() {
            Text('Deck:').fontSize(15).fontWeight(FontWeight.Bold).fontColor('#1F1F1F').width(72).padding({ left: 16 })
              .onClick(() => console.info('TODO: open deck picker (label tap)'));
            Text(this.deckName).fontSize(15).fontColor('#1F1F1F').layoutWeight(1).padding({ left: 8 })
              .onClick(() => {
                const idx: number = this.deckNames.indexOf(this.deckName);
                this.deckName = this.deckNames[(idx + 1) % this.deckNames.length];
              });
            Text('▾').fontSize(14).fontColor('#5F6368').margin({ right: 16 })
              .onClick(() => console.info('TODO: open deck spinner'));
          }
          .width('100%').height(56).alignItems(VerticalAlign.Center)
          .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })
          .onClick(() => {
            const idx: number = this.deckNames.indexOf(this.deckName);
            this.deckName = this.deckNames[(idx + 1) % this.deckNames.length];
          });

          this.FieldBlock('Text', this.frontText, (v: string) => { this.frontText = v; });
          this.FieldBlock('Back Extra', this.backExtraText, (v: string) => { this.backExtraText = v; });
          this.TagsRow();
          this.CardsRow();
        }
        .width('100%');
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto);

      this.FormatToolbar();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}
