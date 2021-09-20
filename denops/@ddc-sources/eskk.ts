import {
  BaseSource,
  Candidate,
  Context,
} from "https://deno.land/x/ddc_vim@v0.4.0/types.ts#^";
import { Denops } from "https://deno.land/x/ddc_vim@v0.4.0/deps.ts#^";

export class Source extends BaseSource {
  isBytePos = true;

  async getCompletePosition(args: {
    denops: Denops,
    context: Context,
  }): Promise<number> {
    const enabled = await args.denops.call('eskk#is_enabled') as boolean;
    if (!enabled) {
      return -1;
    }
    if (/[a-zA-Z]$/.test(args.context.input)) {
      return -1;
    }
    return args.denops.call('eskk#complete#eskkcomplete', 1, '');
  }

  async gatherCandidates(args: {
    denops: Denops,
    completeStr: string,
  }): Promise<Candidate[]> {
    return args.denops.call('eskk#complete#eskkcomplete', 0, args.completeStr);
  }
}
