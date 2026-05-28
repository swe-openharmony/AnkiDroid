// Page: NoteEditorPage

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MockDataSource } from '../common/MockDataSource';

const TAG = 'NoteEditorPage';

interface TypeDef {
  type: string;
  fields: string[];
  template: string;
}

interface FormatButtonRaw {
  glyph: string;
  label: string;
  fontWeight: string;
  italic: boolean;
  underline: boolean;
}

interface NoteEditorFile {
  types: TypeDef[];
  deckNames: string[];
  formatButtons: FormatButtonRaw[];
}

@Entry
@Component
struct NoteEditorPage {
  @State private types: TypeDef[] = [];
  @State private noteTypes: string[] = [];
  @State private deckNames: string[] = [];
  @State private formatButtons: FormatButtonRaw[] = [];

  @State private noteType: string = 'Basic';
  @State private deckName: string = 'Default';

  @State private fieldLabels: string[] = [];
  @State private fieldTexts: string[] = [];
  @State private focusedIndex: number = 0;
  @State private clozeMax: number = 0;
  @State private tags: string = '';

  @State private typePickerOpen: boolean = false;
  @State private deckPickerOpen: boolean = false;
  @State private mediaPanelOpen: boolean = false;
  @State private errorMsg: string = '';

  private mediaOptions: string[] = ['Photos', 'Camera', 'Files'];

  aboutToAppear(): void {
    this.loadNoteEditor();
  }

  private async loadNoteEditor(): Promise<void> {
    try {
      const data = await MockDataSource.loadJson<NoteEditorFile>(this, 'mock_note_editor.json');
      this.types = data.types;
      this.deckNames = data.deckNames;
      this.formatButtons = data.formatButtons;
      this.noteTypes = this.types.map((t: TypeDef) => t.type);
      if (this.noteTypes.length > 0) {
        this.noteType = this.noteTypes[0];
      }
      this.rebuildFields(this.noteType);
      hilog.info(0x0000, TAG, 'loaded %{public}d types, %{public}d decks', this.types.length, this.deckNames.length);
    } catch (e) {
      hilog.error(0x0000, TAG, 'load failed: %{public}s', String(e));
    }
  }

  // ── type helpers ────────────────────────────────────────────────────
  private typeDef(t: string): TypeDef {
    for (const d of this.types) {
      if (d.type === t) {
        return d;
      }
    }
    const fallback: TypeDef = { type: t, fields: ['Front', 'Back'], template: 'Card 1' };
    return fallback;
  }

  private cardsLabel(): string {
    return this.typeDef(this.noteType).template;
  }

  private rebuildFields(t: string): void {
    const fs = this.typeDef(t).fields;
    this.fieldLabels = fs;
    this.fieldTexts = fs.map((_f: string) => '');
    this.focusedIndex = 0;
    this.clozeMax = 0;
    this.errorMsg = '';
  }

  // ── interactions ────────────────────────────────────────────────────
  private selectType(t: string): void {
    this.noteType = t;
    this.typePickerOpen = false;
    this.rebuildFields(t);   // fields rebuild per new type (场景二 step 2)
  }

  private selectDeck(d: string): void {
    this.deckName = d;
    this.deckPickerOpen = false;   // does not touch type / fields (场景二 step 3)
  }

  private setText(i: number, v: string): void {
    const arr = this.fieldTexts.slice();
    arr[i] = v;
    this.fieldTexts = arr;
  }

  private applyFormat(kind: string): void {
    const i = this.focusedIndex;
    if (i < 0 || i >= this.fieldTexts.length) {
      return;
    }
    const t = this.fieldTexts[i];
    let out = t;
    if (kind === 'bold') {
      out = `<b>${t}</b>`;
    } else if (kind === 'italic') {
      out = `<i>${t}</i>`;
    } else if (kind === 'underline') {
      out = `<u>${t}</u>`;
    } else if (kind === 'heading') {
      out = `<h1>${t}</h1>`;
    } else if (kind === 'hr') {
      out = `${t}<hr>`;
    } else if (kind === 'mathjax') {
      out = `\\(${t}\\)`;
    } else if (kind === 'clozeNew') {
      this.clozeMax = this.clozeMax + 1;
      out = `{{c${this.clozeMax}::${t}}}`;
    } else if (kind === 'clozeSame') {
      if (this.clozeMax === 0) {
        this.clozeMax = 1;
      }
      out = `{{c${this.clozeMax}::${t}}}`;
    }
    const arr = this.fieldTexts.slice();
    arr[i] = out;
    this.fieldTexts = arr;
  }

  private applyByLabel(label: string): void {
    if (label === 'Bold') {
      this.applyFormat('bold');
    } else if (label === 'Italic') {
      this.applyFormat('italic');
    } else if (label === 'Underline') {
      this.applyFormat('underline');
    } else if (label === 'Heading') {
      this.applyFormat('heading');
    } else if (label === 'Horizontal rule') {
      this.applyFormat('hr');
    } else if (label === 'MathJax') {
      this.applyFormat('mathjax');
    } else if (label === 'Cloze new') {
      this.applyFormat('clozeNew');
    } else if (label === 'Cloze same') {
      this.applyFormat('clozeSame');
    }
  }

  private onSave(): void {
    this.errorMsg = '';
    const first = this.fieldTexts.length > 0 ? this.fieldTexts[0].trim() : '';
    if (this.noteType === 'Cloze') {
      const hasCloze = this.fieldTexts.some((x: string) => x.indexOf('{{c') >= 0);
      if (!hasCloze) {
        this.errorMsg = 'Please add a cloze deletion';
        return;
      }
    } else {
      if (first.length === 0) {
        this.errorMsg = 'The first field is empty';
        return;
      }
    }
    // validation passed → write + close (success returns to previous page)
    router.back();
  }

  // ── builders ────────────────────────────────────────────────────────
  @Builder
  private TopBar() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('←').fontSize(22).fontColor('#FFFFFF');
      }
      .width(48).height(48).backgroundColor(Color.Transparent)
      .accessibilityText('Navigate up').margin({ left: 4 })
      .onClick(() => router.back());

      Text('Add').fontSize(20).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
        .layoutWeight(1).margin({ left: 8 });

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('✓').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold);
      }
      .width(48).height(48).backgroundColor(Color.Transparent)
      .accessibilityText('Save').onClick(() => this.onSave());

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('👁').fontSize(18).fontColor('#FFFFFF');
      }
      .width(48).height(48).backgroundColor(Color.Transparent)
      .accessibilityText('Preview').onClick(() => hilog.info(0x0000, TAG, 'preview'));

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('⋮').fontSize(22).fontColor('#FFFFFF').fontWeight(FontWeight.Bold);
      }
      .width(48).height(48).backgroundColor(Color.Transparent)
      .accessibilityText('More options').margin({ right: 4 })
      .onClick(() => hilog.info(0x0000, TAG, 'more'));
    }
    .width('100%').height(64).alignItems(VerticalAlign.Center)
    .backgroundColor('#03A9F4');
  }

  @Builder
  private PickerRow(id: string, label: string, onTap: () => void) {
    Row() {
      Text(label).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#1F1F1F')
        .width(72).padding({ left: 16 });
      // Read @State directly (not via a value param) so the row stays reactive
      // when the selection changes.
      Text(id === 'deck' ? this.deckName : this.noteType)
        .fontSize(15).fontColor('#1F1F1F').layoutWeight(1).padding({ left: 8 });
      Text('▾').fontSize(14).fontColor('#5F6368').margin({ right: 16 });
    }
    .width('100%').height(56).alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })
    .onClick(() => onTap());
  }

  @Builder
  private DropdownMenu(items: string[], onPick: (s: string) => void) {
    Column() {
      ForEach(items, (it: string) => {
        Text(it).width('100%').fontSize(15).fontColor('#1F1F1F')
          .padding({ left: 24, right: 24, top: 14, bottom: 14 })
          .onClick(() => onPick(it));
      }, (it: string) => it);
    }
    .width('100%').backgroundColor('#FAFAFA')
    .border({ width: { bottom: 1 }, color: '#E0E0E0' });
  }

  @Builder
  private FieldBlock(label: string, index: number) {
    Column() {
      Row() {
        Text(label).fontSize(15).fontColor('#1F1F1F').layoutWeight(1).padding({ left: 16 });
        Text('📌').fontSize(16).fontColor('#9AA0A6').width(40).height(40).textAlign(TextAlign.Center)
          .accessibilityText(`Make field ${label} sticky`);
        Text('📎').fontSize(16).fontColor('#5F6368').width(40).height(40).textAlign(TextAlign.Center)
          .accessibilityText(`Attach multimedia to ${label}`)
          .onClick(() => { this.focusedIndex = index; this.mediaPanelOpen = true; });
        Text('▲').fontSize(13).fontColor('#5F6368').width(40).height(40).textAlign(TextAlign.Center)
          .margin({ right: 8 });
      }
      .width('100%').alignItems(VerticalAlign.Center).padding({ top: 8 });

      TextArea({ placeholder: '', text: this.fieldTexts[index] })
        .width('100%').height(80).fontSize(15).fontColor('#1F1F1F')
        .backgroundColor(Color.Transparent).borderRadius(0)
        .padding({ left: 16, right: 16, top: 4, bottom: 8 })
        .onChange((v: string) => this.setText(index, v))
        .onFocus(() => { this.focusedIndex = index; })
        .onClick(() => { this.focusedIndex = index; });
    }
    .width('100%').border({ width: { bottom: 0.5 }, color: '#E0E0E0' });
  }

  @Builder
  private TagsRow() {
    Row() {
      Text('Tags: ').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F1F1F').padding({ left: 16 });
      Text(this.tags).fontSize(14).fontColor('#5F6368').layoutWeight(1);
    }
    .width('100%').height(56).alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 0.5 }, color: '#E0E0E0' });
  }

  @Builder
  private CardsRow() {
    Row() {
      Text(`Cards: ${this.cardsLabel()}`)
        .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F1F1F').padding({ left: 16 });
      Blank().layoutWeight(1);
    }
    .width('100%').height(56).alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 0.5 }, color: '#E0E0E0' });
  }

  @Builder
  private FormatToolbar() {
    // Equal-width row so all 9 buttons stay laid out + tappable (they fit the
    // phone width; an explicit per-button width was not honored inside a Scroll).
    Row() {
      ForEach(this.formatButtons, (b: FormatButtonRaw) => {
        Text(b.glyph)
          .fontSize(16).fontColor('#1F1F1F')
          .fontWeight(b.fontWeight === 'bold' ? FontWeight.Bold : FontWeight.Regular)
          .fontStyle(b.italic ? FontStyle.Italic : FontStyle.Normal)
          .decoration({ type: b.underline ? TextDecorationType.Underline : TextDecorationType.None })
          .layoutWeight(1).height(48).textAlign(TextAlign.Center)
          .accessibilityText(b.label)
          .onClick(() => this.applyByLabel(b.label));
      }, (b: FormatButtonRaw) => b.label);
    }
    .width('100%').height(48).backgroundColor('#F5F5F5');
  }

  build() {
    Column() {
      this.TopBar();

      if (this.errorMsg.length > 0) {
        Text(this.errorMsg)
          .width('100%').fontSize(14).fontColor('#FFFFFF')
          .backgroundColor('#D32F2F').padding({ left: 16, right: 16, top: 10, bottom: 10 });
      }

      Scroll() {
        Column() {
          this.PickerRow('type', 'Type:', () => { this.typePickerOpen = !this.typePickerOpen; this.deckPickerOpen = false; });
          if (this.typePickerOpen) {
            this.DropdownMenu(this.noteTypes, (s: string) => this.selectType(s));
          }
          this.PickerRow('deck', 'Deck:', () => { this.deckPickerOpen = !this.deckPickerOpen; this.typePickerOpen = false; });
          if (this.deckPickerOpen) {
            this.DropdownMenu(this.deckNames, (s: string) => this.selectDeck(s));
          }

          ForEach(this.fieldLabels, (label: string, i: number) => {
            this.FieldBlock(label, i);
          }, (label: string, i: number) => `${label}_${i}`);

          this.TagsRow();
          this.CardsRow();

          if (this.mediaPanelOpen) {
            Column() {
              Text('Add media').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#1F1F1F')
                .width('100%').padding(12);
              this.DropdownMenu(this.mediaOptions, (s: string) => {
                const i = this.focusedIndex;
                const arr = this.fieldTexts.slice();
                arr[i] = `${arr[i]}[${s} attached]`;
                this.fieldTexts = arr;
                this.mediaPanelOpen = false;
              });
            }
            .width('100%').backgroundColor('#FFF8E1');
          }
        }
        .width('100%');
      }
      .layoutWeight(1).width('100%').scrollBar(BarState.Auto);

      this.FormatToolbar();
    }
    .width('100%').height('100%').backgroundColor('#FFFFFF');
  }
}
