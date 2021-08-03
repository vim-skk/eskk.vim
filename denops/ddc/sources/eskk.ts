import {
  BaseSource,
  Candidate,
  Context,
  DdcOptions,
  Denops,
  SourceOptions,
} from "https://deno.land/x/ddc_vim@v0.0.9/types.ts";
import { fn, } from "https://deno.land/x/ddc_vim@v0.0.9/deps.ts";

export class Source extends BaseSource {
  isBytePos = true;

  async getCompletePosition(
    denops: Denops,
    context: Context,
    _options: DdcOptions,
    _sourceOptions: SourceOptions,
    _sourceParams: Record<string, unknown>,
  ): Promise<number> {
    const enabled = await denops.call('eskk#is_enabled') as boolean;
    if (!enabled) {
      return -1;
    }
    if (/[a-zA-Z]$/.test(context.input)) {
      return -1;
    }
    return denops.call('eskk#complete#eskkcomplete', 1, '');
  }

  async gatherCandidates(
    denops: Denops,
    _context: Context,
    _ddcOptions: DdcOptions,
    _sourceOptions: SourceOptions,
    _sourceParams: Record<string, unknown>,
    completeStr: string,
  ): Promise<Candidate[]> {
    return denops.call('eskk#complete#eskkcomplete', 0, completeStr);
  }
}
