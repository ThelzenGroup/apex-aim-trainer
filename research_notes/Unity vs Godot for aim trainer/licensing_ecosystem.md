# Unity vs Godot for a PC Apex-style aim trainer: licensing, cost, project health, ecosystem, real-world use, publishing (state as of 7 October 2026)

Research notes. All facts were retrieved on 2026-10-07 unless marked otherwise. Unity's own pages (unity.com) were read directly. Where only a search-engine summary or a secondary aggregator was available, this is flagged.

---

## 1. Licensing and cost (Unity plans, Runtime Fee history, Godot MIT/Foundation)

### Takeaway
A solo or small team with no budget pays nothing in either engine. Unity Personal is free up to $200K in combined revenue and funding over 12 months, and since Unity 6 its splash screen is optional. Above that, Unity Pro costs $2,310 per seat per year (2026 price) and is also required for consoles. Godot is MIT-licensed with no fees, thresholds or splash screen at any revenue level. The 2023 Runtime Fee was never implemented and was cancelled on 12 September 2024. Unity has since moved to annual price rises of 8% (2025) and 5% (2026).

### Cited Findings

**Unity: current plans and thresholds (2026)**
- Unity Personal is free. "This plan is available to customers with up to $200,000 in revenue and funding." The Personal plan card says "Splash screen optional with Unity 6". — [Unity Pricing Changes](https://unity.com/products/pricing-updates)
- Personal eligibility: individuals and hobbyists qualify "if the amount generated in connection with their use of Unity is less than $200K USD". Small businesses qualify if "aggregate gross revenue and funding are less than $200K USD" (measured over the prior 12 months). Personal is "For gaming and entertainment applications only." — [Unity Plans & Pricing](https://unity.com/products/compare-plans)
- Personal includes: "Publish to web, desktop, AR/VR, and mobile", Unity Cloud access, "Unity's MCP access", "Command Line Interface access", and a 14-day trial of Unity AI tools (paid after the trial). Console deployment and splash-screen *customization* are marked as Pro features. — [Unity Plans & Pricing](https://unity.com/products/compare-plans)
- Unity Pro is "Required for businesses with over $200K in funding or annual revenue". Its 2026 price is **$2,310/yr per seat prepaid yearly, or $210/mo per seat paid monthly**. Pro adds "Build and publish for game consoles and Apple Vision Pro", expedited support, extra cloud storage and 2,000 monthly Unity AI credits. — [Unity Pricing Changes](https://unity.com/products/pricing-updates); [Unity Plans & Pricing](https://unity.com/products/compare-plans)
- Unity Enterprise is "Required for businesses with more than $25M in annual revenue". It has custom pricing, "A minimum subscription requirement may apply", and adds read-only source access and 3 years of extended LTS. — [Unity Pricing Changes](https://unity.com/products/pricing-updates)
- Subscription terms: "There is no cancellation policy or reimbursement for a subscription". You cannot downgrade during the commitment period. — [Unity Plans & Pricing](https://unity.com/products/compare-plans)
- Ownership: "Do I own the content I create using Unity? Yes." — [Unity Plans & Pricing](https://unity.com/products/compare-plans)

**Unity: price history after the Runtime Fee**
- 2026 change, announced 10 November 2025: "Unity Pro and Enterprise will see a 5% price increase, starting January 12th, 2026", applied "in line with last year's commitment to predictable, annual price adjustments." Existing subscribers pay the new price at their next renewal on or after 12 January 2026. — [Unity Pricing Changes](https://unity.com/products/pricing-updates)
- The 2026 increase took Pro from $2,200 to $2,310 per seat per year and from $200 to $210 per month. (This figure comes from a search summary of the 80.lv and CG Channel coverage. Both sites blocked direct fetch. The $2,310 and $210 endpoints are confirmed by Unity's own page.) — [80.lv](https://80.lv/articles/unity-announces-its-upcoming-2026-price-changes); [CG Channel](https://www.cgchannel.com/2025/11/price-of-paid-unity-subscriptions-to-rise-but-free-subs-extended/)
- 2025 change: when the Runtime Fee was cancelled (September 2024), Unity reverted to seat-based pricing. Unity Pro rose 8% and Enterprise 25% on 1 January 2025. CEO Matt Bromberg said the "intention [is] to revert to a more traditional cycle of considering any potential price increases only on an annual basis." — [Wikipedia: Unity Technologies](https://en.wikipedia.org/wiki/Unity_Technologies) (citing Reuters and GamesIndustry.biz, 12 Sep 2024)
- Threshold timeline: Personal's limit rose from $100K to $200K "when Unity 6 was released on October 17, 2024". The Pro band ($200,001 to $24,999,999) and the Enterprise band ($25M+) took effect 1 January 2025 at purchase or renewal. — [Unity Pricing Changes](https://unity.com/products/pricing-updates)
- Editor terms: the Editor Software Terms were updated on 10 October 2024 "to remove language related to the recently canceled Unity Runtime Fee". You "must accept the updated October 10, 2024 Unity Editor Software Terms to use Unity 6". Users can stay on previously accepted terms "for as long as you keep using that named version of Unity Editor". Unity keeps current and previous terms in a GitHub repository. — [Unity Pricing Changes](https://unity.com/products/pricing-updates)
- Other 2026 packaging changes:
  - Havok Physics is no longer included with Pro, Enterprise or Industry from Unity 6.3 LTS onward. Havok becomes a third-party Microsoft extension.
  - From 1 March 2026, Unity Version Control in the public cloud has unlimited seats (Personal was previously limited to 3 free seats).
  - The free tier now includes 25 GB of storage (up from 5 GB) and 100 GB of egress per month. Egress beyond that costs $0.10/GB.
  - Monthly free build minutes: 200 Windows (Micro), 100 Linux and 100 Mac.
  - "If you cross a free-tier limit, access is blocked immediately" until a card is added.
  - [Unity Pricing Changes](https://unity.com/products/pricing-updates); [Unity Plans & Pricing](https://unity.com/products/compare-plans)

**Unity: Runtime Fee (2023–2024), now historical**
- September 2023: Unity announced per-install "Runtime Fees" above thresholds. Developers objected to the extra cost, the risk of inaccurate or malicious install counts, and fees that applied retroactively. — [Wikipedia: Unity Technologies](https://en.wikipedia.org/wiki/Unity_Technologies)
- 22 September 2023 revision: Personal would pay no fee and its cap would rise from $100K to $200K. The fee would apply only to games made with Unity 2024 and later, with no retroactive fees. It would be self-reported, at the lesser of 2.5% of monthly revenue or an engagement-based amount. — [Wikipedia: Unity Technologies](https://en.wikipedia.org/wiki/Unity_Technologies)
- 9 October 2023: CEO John Riccitiello left. — [Wikipedia: Unity Technologies](https://en.wikipedia.org/wiki/Unity_Technologies)
- 12 September 2024 cancellation: "As of September 12, 2024, we decided to cancel it… effective immediately, and will not apply to any games made with Unity 6 or any other version of Unity… No new or existing Unity games have been, or will be, subject to the Runtime Fee." — [Unity Pricing Changes](https://unity.com/products/pricing-updates)
- Lasting reputational effect: Wired said Unity's reputation "could be irreparably damaged", and some developers said they would not return. — [Wikipedia: Unity Technologies](https://en.wikipedia.org/wiki/Unity_Technologies)
- Road to Vostok, a solo-developed hardcore FPS, was ported from Unity to Godot because of the September 2023 Runtime Fee. — [Wikipedia: Road to Vostok](https://en.wikipedia.org/wiki/Road_to_Vostok)

**Godot: licence and costs**
- Godot is "an open source game engine released under the MIT License". It can export to "desktop, mobile, browser, and console platforms without licensing fees." — [Wikipedia: Godot](https://en.wikipedia.org/wiki/Godot_(game_engine))
- Godot is "MIT-licensed and fully open source, no NDAs, no restricted tools, and no legal liability." — [Godot Console Support page](https://godotengine.org/consoles/)
- Footer: "© 2007-2026 Juan Linietsky, Ariel Manzur and contributors. Hosted by the Godot Foundation." — [Godot 4.7 release page](https://godotengine.org/releases/4.7/)
- The only costs that apply to Godot are optional third parties: console porting middleware or services (see section 5) and paid assets.

**Godot Foundation: funding and stability**
- The Godot Development Fund page, read on 7 Oct 2026, showed live counters: **€238,010 in one-time donations this year, €35,434 per month in recurring donations, 1,830 members, 23 sponsors**. Corporate sponsors listed include ShipThis and Ziva.sh. — [Godot Development Fund](https://fund.godotengine.org/)
- History: Godot joined the Software Freedom Conservancy in 2015. Funding included a $20K Mozilla MOSS award (2016), $24K from Microsoft for C# (2017) and a $250K Epic MegaGrant (2020). The Godot Foundation was announced in November 2022 to replace the SFC as Godot's home. After the Unity controversy, Re-Logic (Terraria) donated $100K plus $1,000 per month. — [Wikipedia: Godot](https://en.wikipedia.org/wiki/Godot_(game_engine))
- July 2023 baseline (old, flagged by the site as possibly outdated): about $14K/month in Patreon income at the time; "10 contractors… roughly 40,000 USD per month"; the Foundation said it was spending more than it took in. — [Godot: Funding Breakdown & Hiring Process (11 Jul 2023)](https://godotengine.org/article/funding-breakdown-and-hiring-process/)
- The Foundation is a Dutch non-profit (Stichting Godot), led by a Board of Directors and an Executive Director, with remote contractors. It has committed to annual reports from 2024. (Board and policy details are from a search summary.) — [Godot Foundation Team](https://godot.foundation/team/); [Godot Foundation Key Policies](https://godot.foundation/policies-and-procedures/key-policies)
- Executive Director Emilio Coppola (July 2025): "After the initial peak of interest, the community and contributions doubled and continued growing at a faster rate than before." He also said: "Since we are a non-profit organisation, we don't have shareholders… We don't charge users for using the engine." — [GamesIndustry.biz, 17 Jul 2025](https://www.gamesindustry.biz/two-years-after-the-unity-controversy-how-are-things-going-with-godot)
- Forkability as insurance: "Even if the Godot Foundation implodes overnight, it's not going anywhere" (developer quoted). — [GamesIndustry.biz](https://www.gamesindustry.biz/two-years-after-the-unity-controversy-how-are-things-going-with-godot)

### Inferences
- For this project, revenue and funding below $200K/yr keep Unity at $0. Crossing $200K (combined revenue and funding, not profit) adds $2,310 per seat per year, which is currently rising about 5–8% a year. At any revenue Godot's engine cost stays $0. In practice the threshold matters mostly if the aim trainer succeeds commercially or takes investment or publisher funding. Funding counts toward Unity's cap.
- Since Unity 6, the "Made with Unity" splash is optional on Personal. Unity's page words it as "optional with Unity 6", which implies older Editor versions on Personal still require the splash. So the old splash downside no longer applies to new projects.
- Unity's current terms let you stay on the terms you accepted for a given Editor version. That reduces, but does not remove, the risk of future pricing changes. Subscription prices can still change at renewal for anyone on Pro.
- Godot's Foundation finances are modest in absolute terms: about €35K/month recurring plus about €238K one-off so far in 2026. That is well above the 2023 figure of $14K/month. The MIT licence and fork rights mean the project does not depend on the Foundation surviving.

### Gaps
- No full Godot Foundation annual financial report for 2024 or 2025 was found or fetched, so total annual income, expenses and paid headcount for 2025–26 are unknown.
- Unity's original September 2023 per-install fee schedule (e.g., $0.20/install) was not verified from a primary source in this session.
- The Unity Pro 2024 base price (before the 8% rise) was not directly verified. Only the $2,200 to $2,310 step (via search summary) and the current $2,310 (primary) are sourced.

---

## 2. Engine trajectory and company/project health (through October 2026)

### Takeaway
Unity has shipped a steady Unity 6.x cadence: 6.0 LTS, then 6.1 to 6.6 roughly every 3–5 months, with 6.7 LTS expected in late 2026. Unity 7 (CoreCLR/.NET) reached alpha on 6 October 2026. As a company, Unity still loses money (2025 net loss of $401.5M on $1.85B revenue), has had repeated layoffs, closed the ironSource ad network in 2026, and is in litigation with AppLovin. Godot ships a feature release every 4–6 months (4.3 Aug 2024 to 4.7 Jun 2026, 4.8 in dev). Each release has 300–400 contributors, and both donations and community size are growing.

### Cited Findings

**Unity 6.x release cadence**
| Version | Release | Support status (Oct 2026) |
|---|---|---|
| 6.0 LTS | GA 17 Oct 2024 ([Unity](https://unity.com/products/pricing-updates)) | security support ends 16 Oct 2026; extended LTS to 16 Oct 2027 ([endoflife.date](https://endoflife.date/unity)) |
| 6.1 | 23 Apr 2025 | ended |
| 6.2 | 12 Aug 2025 | ended |
| 6.3 LTS | 4–5 Dec 2025 | supported to 4 Dec 2027 (extended to 4 Dec 2028) |
| 6.4 | 18 Mar 2026 (shipped with Unity Studio GA) | ended 17 Jun 2026 |
| 6.5 | 15 Jun 2026 | ended 31 Aug 2026 |
| 6.6 | 31 Aug / 1 Sep 2026 | current; latest patch 6000.6.4f1 (1 Oct 2026) |
| 6.7 LTS | expected late 2026 | — |
| 7.0 alpha | 6 Oct 2026 | pre-release |
- Sources: [endoflife.date/unity](https://endoflife.date/unity) (updated 2 Oct 2026); [Unity 6.3 LTS blog](https://unity.com/blog/unity-6-3-lts-is-now-available); [CG Channel: Unity 6.4 and Unity Studio](https://www.cgchannel.com/2026/03/unity-releases-unity-6-4-and-unity-studio/); [Unity Discussions: 6.5 available](https://discussions.unity.com/t/unity-6-5-is-now-available/1723176); [GameFromScratch: Unity 6.6 Released (1 Sep 2026)](https://gamefromscratch.com/unity-6-6-released/). The 6.7 LTS timing comes from a search summary.
- Unity 6.6 highlights: native dictionary serialization; WebGPU production-ready; DXC shader compiler for DX12; a compute lightmap baker; Fast Enter Play Mode on by default "to prepare for the move to CoreCLR in Unity 7"; a Build Analysis window. — [GameFromScratch](https://gamefromscratch.com/unity-6-6-released/)
- Unity 7 Alpha (6 Oct 2026):
  - It is the first CoreCLR-powered Editor without Mono, but "still targets C# 9 and .NET Standard 2.1".
  - .NET 10 and C# 14 will come later in the 7.0 cycle: "We cannot commit to a public date yet".
  - The first supported 7.0 aims for "parity with Unity 6.7LTS"; performance work is deferred to a later 7.x LTS.
  - An MSBuild-based project workflow is coming.
  - "not recommend[ed] for production use".
  - [GameFromScratch: Unity 7 Alpha Released](https://gamefromscratch.com/unity-7-alpha-released/)
- Unity's business AI and tooling moves: Unity Studio, a browser-based no-code editor, reached GA in 2026. Unity and Google announced "Playground", a generative-AI game-creation platform, on 7 October 2026. — [Wikipedia: Unity Technologies](https://en.wikipedia.org/wiki/Unity_Technologies) (citing [Bloomberg, 7 Oct 2026](https://www.bloomberg.com/news/articles/2026-10-07/google-unity-launch-platform-to-create-video-games-from-prompts))

**Unity as a company**
- Financials (FY2025): revenue of US$1.85B, operating income of −US$479M, net income of −US$401.5M, total equity of −US$3.24B. Employees: 4,987 (2024). — [Wikipedia: Unity Technologies](https://en.wikipedia.org/wiki/Unity_Technologies) (infobox, citing SEC 10-K)
- Leadership: Riccitiello left in October 2023, Jim Whitehurst served as interim CEO, and **Matthew Bromberg (ex-Zynga COO) became permanent CEO in May 2024**. — [Wikipedia: Unity Technologies](https://en.wikipedia.org/wiki/Unity_Technologies)
- Layoffs:
  - 2022–2024: about 200 (June 2022); 284 (January 2023); 600 (May 2023); 265 (November 2023, Weta); **1,800 (January 2024, about 25% of staff, a "company reset")**. — [Wikipedia: Unity Technologies](https://en.wikipedia.org/wiki/Unity_Technologies)
  - February 2025: another restructuring hit the CTO, Engine Product and Ads teams. Bromberg's memo said "2025 is going to be the year where we bring to market products and services that will transform our position" and "Data is our future… The Runtime must enable both [engine insight and ads ROI]." — [GameFromScratch, 11 Feb 2025](https://gamefromscratch.com/more-layoffs-and-restructuring-at-unity/)
  - Coverage of that wave described it as Unity's sixth wave of layoffs in three years, totalling about 3,500 employees, and said the whole Unity Behavior team was cut. — [Gamereactor](https://www.gamereactor.eu/unity-makes-more-job-cuts-its-sixth-wave-of-layoffs-in-three-years-1496363); [PocketGamer.biz](https://www.pocketgamer.biz/unity-lays-off-staff-and-axes-behavior-team/) (search summaries; direct fetch blocked)
- 2026 restructuring:
  - On 27 March 2026, Unity announced it would sunset the ironSource Ads Network (discontinued 30 April 2026) and sell the Supersonic publishing label, focusing on "Unity Vector".
  - It recorded $279M of impairment charges in Q1 2026.
  - The stock rose about 33% on the news.
  - Sources (search summaries): [Game Developer](https://www.gamedeveloper.com/business/unity-sunsetting-ads-network-and-divesting-publishing-label-supersonic); [PocketGamer.biz](https://www.pocketgamer.biz/unity-to-shut-down-ironsource-ads-network-and-explore-supersonic-sale-as-revenue-beats-guidance/); [SEC 10-Q Q1 FY2026](https://www.sec.gov/Archives/edgar/data/0001810806/000181080626000032/unity-20260331.htm); [Simply Wall St](https://simplywall.st/stocks/us/software/nyse-u/unity-software/news/unity-software-u-is-up-328-after-exiting-legacy-ads-to-refoc/amp)
- Litigation: on 2 October 2026, AppLovin sued Unity and sought a temporary restraining order. It alleges Unity's Ad Quality SDK harvested AppLovin ad data to train Unity's models; the allegations are unadjudicated. Unity called it "a classic case of a dominant incumbent resorting to litigation and intimidation." — [GameFromScratch: AppLovin Sues Unity](https://gamefromscratch.com/applovin-sues-unity/)
- Market value: Unity peaked at $57B (November 2021) and fell to about $6B by September 2024. — [Wikipedia: Unity Technologies](https://en.wikipedia.org/wiki/Unity_Technologies)

**Godot release cadence and features**
- 4.3: 15 Aug 2024. 4.4: 5 Mar 2025 (Jolt physics integration, .NET 8). 4.5: September 2025 (stencil buffer, TileMapLayer collision rework). 4.6: January 2026. 4.7: June 2026. 4.7.2 maintenance: 18 Aug 2026. — [Wikipedia: Godot](https://en.wikipedia.org/wiki/Godot_(game_engine))
- Exact-date discrepancy: one secondary source gives 4.4 = 3 Mar 2025, 4.5 = 15 Sep 2025 and 4.6 = 26 Jan 2026. Others give 4.6 = 27 Jan 2026. Treat dates as ±1 day. — [Tech Insider](https://tech-insider.org/godot-vs-unity-engine-2026/); [GameFromScratch: Godot 4.6 Released](https://gamefromscratch.com/godot-4-6-released/)
- 4.6 highlights:
  - Jolt became the default 3D physics engine for new projects ("Existing projects aren't affected").
  - Direct3D 12 became the default renderer on Windows for new projects.
  - New "Modern" editor theme.
  - LibGodot (engine as a library).
  - "Close to 400 contributors… 2,001 (!) commits".
  - [Godot 4.6 release page](https://godotengine.org/releases/4.6/)
- 4.7 highlights (18 Jun 2026):
  - HDR output on Windows, macOS, iOS, visionOS and Linux (Wayland).
  - AreaLight3D.
  - **The new Asset Store replaces the Asset Library**.
  - SDL3 controller support extended to iOS (already used on Windows, macOS and Linux).
  - "Well over 300 contributors… over 1,600 pull requests".
  - "Production-ready" support for Valve's Steam Frame.
  - [Godot 4.7 release page](https://godotengine.org/releases/4.7/); date and "1,265 fixes from 309 contributors since 4.6" from search summary of the [GitHub 4.7-stable release](https://github.com/godotengine/godot/releases/tag/4.7-stable)
- Godot 4.8 is in development (dev6 and dev7 builds by early October 2026). — [GameFromScratch sidebar "Godot 4.8 Dev6 & Dev7 Releases"](https://gamefromscratch.com/unity-7-alpha-released/)
- GitHub repo: 110,926 stars, 25,378 forks and 18,203 open issues on 20 May 2026 (secondary source citing the GitHub API). A search summary reported about 118K stars later in 2026. — [Tech Insider](https://tech-insider.org/godot-vs-unity-engine-2026/)
- W4 Games, a commercial company founded in August 2022 by Linietsky and other Godot team members, sells console ports and services. — [Wikipedia: Godot](https://en.wikipedia.org/wiki/Godot_(game_engine))

### Inferences
- Unity's engine roadmap is active, but 2026 brings a major platform transition. The Unity 7 / CoreCLR migration starts with C# 9 and parity goals, and the modern .NET timing is uncommitted. A new project in late 2026 would probably start on 6.3 LTS or 6.7 LTS and face a migration later.
- Unity's corporate signals are mixed: continuing losses, serial layoffs, divestments, new litigation, and a strategic emphasis on ads, data and AI rather than the editor. Engine development itself continues at a predictable pace, though, and pricing has stabilised under the "annual adjustment" policy.
- Godot's health indicators all point up: steady feature releases with 300–400 contributors each, a growing Development Fund, community growth, and Steam release growth (section 6). The main structural risk is that core development depends on donations and a small paid contractor team.

### Gaps
- Unity's Q2 2026 earnings, current headcount, and any 2026 engine-team layoffs were not verified.
- Godot Foundation paid staff and contractor headcount for 2026 is unknown.
- The Gamereactor and PocketGamer pages could not be fetched directly, so the "sixth wave / about 3,500 total" figure rests on search summaries.

---

## 3. Engines used by existing aim trainers and comparable FPS games

### Takeaway
The market-leading aim trainers do not use Godot. Aimlabs runs on Unity and KovaaK's on a tuned Unreal Engine 4. The engines behind Aimbeast and 3D Aim Trainer could not be verified. Godot aim trainers exist only as small open-source projects, and none was found on Steam. Godot 4 does have one notable commercial FPS, Road to Vostok (solo developer, Early Access April 2026, 180K+ copies in week one). Unity has many shipped shooters (Escape from Tarkov, BattleBit Remastered, Ultrakill, Rust).

### Cited Findings

**Aim trainers**
- **Aimlabs (formerly Aim Lab)** uses the **Unity** engine (infobox: "Engine: Unity"). Developer and publisher: State Space Labs. Steam Early Access began 7 Feb 2018 and the full Windows launch was 16 Jun 2023. It is also on Xbox, PS5 (from 4 Nov 2025), iOS and Android. It has "surpassed 45 million registered players" (2025), and Statespace raised $50M in September 2021. — [Wikipedia: Aimlabs](https://en.wikipedia.org/wiki/Aimlabs)
- **KovaaK's**: the store description says "KovaaK's is built in Unreal Engine… a tweaked Unreal Engine 4", with "All graphical options that affect framerate or input lag… disabled by default" and "over 175,000 player-created scenarios". This text comes from reseller copies of the store description; the current Steam page was fetched and did not name the engine. — [Nuuvem: KovaaK's](https://www.nuuvem.com/om-en/item/kovaaks); [Gamesplanet: KovaaK's Core](https://us.gamesplanet.com/game/kovaak-s-core-steam-key--6418-3); [Steam: KovaaK's](https://store.steampowered.com/app/824270/KovaaKs/)
- **Aimbeast** (Steam app 1100990, released 13 May 2020) offers community scenarios, a "human-like AI" bot movement system, a map editor with Workshop, and ranked duels on dedicated servers. **Engine not confirmed**: the store page does not name it, and SteamDB and PCGamingWiki were blocked. — [Steam: Aimbeast](https://store.steampowered.com/app/1100990/Aimbeast/); [SteamData.ai](https://steamdata.ai/en-US/game/1100990/aimbeast)
- **3D Aim Trainer** (3daimtrainer.com) is browser-based. Inspecting the site's front-end bundle showed a Nuxt (Vue) web app, but nothing conclusive about the game engine. **Engine not confirmed.** — [3D Aim Trainer](https://www.3daimtrainer.com/)
- **Godot aim trainers** (all open-source, none found on Steam):
  - Open Aim Trainer: "Built completely free and powered by the Godot Engine", MIT licence. — [openaimtrainer.com](https://openaimtrainer.com/)
  - LibreAim: a "Free and open source FPS aim trainer made with Godot", now on Codeberg. — [Codeberg: LibreAim](https://codeberg.org/Nokorpo/LibreAim); [GitHub: LibreAim](https://github.com/Nokorpo/LibreAim)
  - Project Aim: Windows, Linux and macOS. — [GitHub](https://github.com/ahmadhayyan/project-aim)
  - SAIM. — [GitHub](https://github.com/JagersEgo/SAIM)
  - A search for Godot aim trainers on Steam found "no clear evidence that any of these are officially available on Steam." (search-based)

**FPS and first-person games shipped with Godot**
- **Road to Vostok** (Godot 4): a hardcore survival FPS by solo developer Antti Leinonen, in Early Access since 7 Apr 2026. "Over 180,000 copies sold in the first week." Its free demo (March 2024) was downloaded over 1.1 million times. It was ported from Unity to Godot over the Runtime Fee. — [Wikipedia: Road to Vostok](https://en.wikipedia.org/wiki/Road_to_Vostok); [PC Gamer](https://www.pcgamer.com/hardcore-survival-shooter-road-to-vostok-is-looking-really-good-after-switching-engines-from-unity-to-godot/); [GamingOnLinux, Apr 2026](https://www.gamingonlinux.com/2026/04/road-to-vostok-is-an-incredibly-impressive-solo-developed-hardcore-survival-shooter/). A figure of "84% of 6,120 reviews positive" comes from a search summary only.
- **Cruelty Squad** (Godot, FPS/immersive sim, 15 Jun 2021). This predates Godot 4. — [Wikipedia](https://en.wikipedia.org/wiki/Cruelty_Squad)
- **Buckshot Roulette** (Godot, first-person but not a shooter; Steam release 4 Apr 2024). — [Wikipedia](https://en.wikipedia.org/wiki/Buckshot_Roulette)
- **Brotato** (Godot, top-down) is "the highest Steam revenue title ever created in… Godot" according to GameDiscoverCo's file-structure scanning. — [GameDiscoverCo, 17 Mar 2026](https://newsletter.gamediscover.co/p/hows-pc-game-engine-usage-changing)

**FPS games shipped with Unity**
- Escape from Tarkov: Unity; version 1.0 released 15 Nov 2025. — [Wikipedia](https://en.wikipedia.org/wiki/Escape_from_Tarkov)
- BattleBit Remastered: Unity; MMO FPS; Early Access 15 Jun 2023. — [Wikipedia](https://en.wikipedia.org/wiki/BattleBit_Remastered)
- Ultrakill: Unity; FPS; Early Access 3 Sep 2020. — [Wikipedia](https://en.wikipedia.org/wiki/Ultrakill)
- Rust: Unity. — [Wikipedia](https://en.wikipedia.org/wiki/Rust_(video_game))
- Genre skew: "Unreal Engine's popularity is significantly higher among FPS, Souls-like projects, Action RPGs", while Unity leads in city builders, turn-based RPGs and roguelikes (Video Game Insights, 2024 data). — [GameDev Reports / VGI, 10 Feb 2025](https://gamedevreports.substack.com/p/video-game-insights-game-engines)

### Inferences
- There is direct precedent for an aim trainer in Unity: Aimlabs is the largest aim trainer, has 45M+ players, and ships on PC and consoles. That shows Unity can deliver a commercial-grade, multi-platform trainer.
- For Godot, the precedents are an indie FPS that sold well (Road to Vostok) and several hobby aim trainers. There is no commercial aim trainer yet, so this project would be among the first notable ones. That may be a marketing hook, but it also means fewer genre-specific reference implementations.
- KovaaK's choice of Unreal (not under evaluation here) reflects how much this genre prioritises input latency and frame rate. Those technical aspects are covered by other researchers.

### Gaps
- The engines of Aimbeast and 3D Aim Trainer remain unverified: SteamDB, PCGamingWiki and GitHub were blocked, and the store pages don't state them.
- Whether KovaaK's has moved to UE5 is unverified.
- No full list was found of competitive or arena FPS games shipped specifically with Godot 4 beyond Road to Vostok. Godot's showcase page content could not be parsed.

---

## 4. Community, learning resources, asset ecosystems and relevant plugins

### Takeaway
Unity still has the much larger ecosystem: roughly 80,000+ Asset Store items versus roughly 3,000 Godot Asset Library entries (both figures from a secondary source), plus a deeper backlog of FPS tutorials. Godot's community is growing fast: about 111K–118K GitHub stars, Brackeys now making Godot tutorials, and a new official Asset Store in 4.7. Steam integration is mature on both sides: GodotSteam for Godot, Steamworks.NET (MIT, 100% API coverage) or Facepunch.Steamworks for Unity.

### Cited Findings

**Community size and learning**
- Godot GitHub: 110,926 stars and 25,378 forks (20 May 2026). The same secondary source rates Godot's documentation "Excellent for an open-source project, but third-party tutorial breadth still trails Unity by a wide margin." — [Tech Insider (secondary, mixed reliability)](https://tech-insider.org/godot-vs-unity-engine-2026/)
- r/godot was reported at about 376K members on 1 October 2026, and the Godot Discord at more than 80,000 members. These figures come from search summaries of aggregator sites and could not be verified because Reddit's API was blocked. — [GummySearch r/godot](https://gummysearch.com/r/godot/); [Ziva: Godot growth stats](https://ziva.sh/blogs/godot-growth-stats)
- Coppola (Godot Foundation, July 2025): there was historically "a lack of resources for learning… just not as many as in Unity. This is changing… popular content creators such as Brackeys are also making Godot tutorials." — [GamesIndustry.biz](https://www.gamesindustry.biz/two-years-after-the-unity-controversy-how-are-things-going-with-godot)
- A developer quoted in the same article: "there is no question that Unity still has more functionality than Godot… For what I make, Godot has everything I need." — [GamesIndustry.biz](https://www.gamesindustry.biz/two-years-after-the-unity-controversy-how-are-things-going-with-godot)
- Unity offers free official learning (Unity Learn, "Unity Essential Pathways"), certifications, and the "Made with Unity" showcase. — [Unity Plans & Pricing (site nav)](https://unity.com/products/compare-plans)
- A third-party comparison (April 2026) said Unity's longer market presence means "more available assets in its asset store and a larger job market", and that console and third-party tool support favour Unity. — [Wikipedia: Godot](https://en.wikipedia.org/wiki/Godot_(game_engine)) (summarising Tech Insider)

**Asset stores**
- Unity Asset Store "in the 80,000+ range" versus "roughly 3,000 in the Godot Asset Library". Godot is "particularly thin on production-ready 3D assets". — [Tech Insider (secondary)](https://tech-insider.org/godot-vs-unity-engine-2026/)
- The Godot Asset Store beta launched in 2025 and, in June 2026 with 4.7, "replaced the asset library". It adds "better previews, ratings, reviews, tags, changelogs, and versioned downloads" and background threading in the editor. — [Wikipedia: Godot](https://en.wikipedia.org/wiki/Godot_(game_engine)); [Godot 4.7 release page](https://godotengine.org/releases/4.7/)
- Coppola: "Many of those [Unity Asset Store] tools are seeing their Godot counterparts being released… [the Asset Store beta is] already seeing an overwhelming amount of submissions." — [GamesIndustry.biz](https://www.gamesindustry.biz/two-years-after-the-unity-controversy-how-are-things-going-with-godot)
- Unity asset portability: Asset Store packages, DOTween, Cinemachine, Photon and similar have no automatic Godot equivalents; "many will need to be rewritten." — [Tech Insider (secondary)](https://tech-insider.org/godot-vs-unity-engine-2026/)

**Steamworks integration**
- **GodotSteam** ships as a precompiled engine module, a GDExtension, or a server build, and has C# support.
  - Documented tutorials cover achievements, authentication, auto-matchmaking, avatars, DLC, cloud sync, leaderboards, lobbies, MultiplayerPeer, networking (messages and sockets), rich presence, stats, Workshop, Steam Input, voice, Mac exporting, and "Exporting and Shipping".
  - "GodotSteamKit" tutorials also exist.
  - [GodotSteam](https://godotsteam.com/)
- **Steamworks.NET** "is a C# Wrapper for Valve's Steamworks API and is completely free and open source under the permissive MIT license". It works "with Unity or non-Unity based .NET projects" and "boasts 100% coverage of the native Steamworks API across all interfaces". — [Steamworks.NET](https://steamworks.github.io/)
- **Facepunch.Steamworks** is an alternative C# wrapper (used by Facepunch's Rust). Its current release status could not be fetched because GitHub API access was blocked. — [GitHub: Facepunch.Steamworks](https://github.com/Facepunch/Facepunch.Steamworks)
- Leaderboards matter for an aim trainer, and both wrappers expose Steam Leaderboards, Stats and Workshop. — [Steamworks.NET](https://steamworks.github.io/); [GodotSteam](https://godotsteam.com/)

**Analytics and services**
- Unity Personal includes the Unity Cloud ecosystem (Version Control, Asset Manager) and Cloud Diagnostics. Version Control in the public cloud has unlimited seats, and the free tier is 25 GB storage with 100 GB/month egress. — [Unity Pricing Changes](https://unity.com/products/pricing-updates); [Unity Plans & Pricing](https://unity.com/products/compare-plans)
- Godot has no first-party analytics service. Third-party options were not researched in depth (see Gaps).

### Inferences
- For an Apex-style trainer, Unity's Asset Store breadth (FPS controllers, weapon and recoil kits, animated humanoid characters, VFX) could shorten development for a solo developer starting with no budget, though many good kits are paid. Godot will more often require building systems from scratch or using smaller community plugins.
- Steam integration is not a differentiator: both have mature, free, MIT-licensed wrappers with leaderboards and Workshop support, which are the key Steam features for an aim trainer with community scenarios.
- The FPS tutorial gap still favours Unity, but it is narrowing. A new developer will find more Unity FPS content, though much of it predates Unity 6.

### Gaps
- Primary counts were not obtained for Unity Asset Store items, Godot Asset Store items (after the June 2026 switch), r/Unity3D membership, or Unity Discord and forum size. Reddit, SteamDB and GitHub APIs were blocked; the asset counts are from one secondary source.
- Godot analytics plugins (e.g., GameAnalytics, Talo, or self-hosted options) and their maintenance status were not researched.
- No systematic count was made of FPS-specific tutorials per engine.

---

## 5. Publishing: Steam, Linux, Steam Deck, macOS, consoles, code signing

### Takeaway
Both engines export to Windows, Linux and macOS at no extra cost. On Unity this works on the free Personal plan; console deployment requires Pro ($2,310 per seat per year) plus platform approval. Godot has no official console exports because of its open-source licence: ports go through third-party middleware or porting houses such as W4 Games (Switch, Xbox Series, PS5), RAWRLAB, Lone Wolf, Pineapple Works and Sickhead. Steam itself costs a $100 recoupable Steam Direct fee per app. A macOS release needs an Apple Developer ID for signing and notarization. Windows signing is optional; Godot can sign on export with SignTool or osslsigncode.

### Cited Findings

**Steam**
- Steam Direct fee: "$100.00 fee for each product". It is recoupable "after your product has at least $1,000.00 Adjusted Gross Revenue". There is "A 30-day waiting period between when you paid the app fee and when you can release your game." — [Steamworks: Steam Direct](https://partner.steamgames.com/steamdirect)
- Steam integration: GodotSteam for Godot; Steamworks.NET or Facepunch.Steamworks for Unity (section 4).

**Desktop platforms**
- Unity Personal: "Publish to web, desktop, AR/VR, and mobile". — [Unity Plans & Pricing](https://unity.com/products/compare-plans)
- Godot exports to desktop Linux, macOS and Windows. It officially supports x86 on all desktop platforms and ARM on macOS and Linux. — [Wikipedia: Godot](https://en.wikipedia.org/wiki/Godot_(game_engine))
- Godot hardware requirements for exported projects: Forward+ needs "Dedicated graphics with full Vulkan 1.2 support" (or integrated graphics with Vulkan 1.0). The Compatibility renderer needs OpenGL 3.3. — [Godot docs: System requirements](https://docs.godotengine.org/en/stable/about/system_requirements.html)
- Godot 4.6 made Direct3D 12 the default renderer for new Windows projects "for more stable driver support and fewer platform quirks". — [Godot 4.6 release page](https://godotengine.org/releases/4.6/)
- Godot 4.7 is "production-ready for the Steam Frame" (Valve's headset) and adds initial Wayland touch support on Linux. — [Godot 4.7 release page](https://godotengine.org/releases/4.7/)
- Valve detailed "Steam Frame and Steam Machine Verified requirements at GDC 2026". — [GameDiscoverCo](https://newsletter.gamediscover.co/p/hows-pc-game-engine-usage-changing)
- Unity's build service includes 100 free Linux and 100 free Mac build minutes per month on every plan, so macOS builds are possible without owning a Mac. — [Unity Plans & Pricing](https://unity.com/products/compare-plans)

**macOS signing and notarization**
- Godot docs: "Projects exported without code signing and notarization will be blocked by Gatekeeper if they are downloaded from unknown sources." Also: "To notarize an app, you must have a valid Apple Developer ID Certificate." Godot supports signing and notarizing from macOS (Xcode codesign and notarytool) and also from Linux or Windows. — [Godot docs: Exporting for macOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html)

**Windows signing**
- "Godot is capable of automatic code signing on export… you must have the Windows SDK (on Windows) or osslsigncode (on any other OS) installed. You will also need a package signing certificate." — [Godot docs: Exporting for Windows](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html)

**Consoles**
- Unity: "Deploy to game consoles" is a Pro, Enterprise or Industry feature and is not available on Personal. — [Unity Plans & Pricing](https://unity.com/products/compare-plans)
- Godot: "While Godot can't offer official support due to its open source license, approved developers can still ship console games using Godot through certified third-party providers."
  - Required steps: register with the console maker, get approved for SDK access, obtain a devkit ("confidential pricing"), use or build console export templates, obtain age ratings, and port in-house or through a vendor.
  - "W4 Games offers official middleware ports for Nintendo Switch, Xbox Series X/S, and PlayStation 5."
  - Listed providers: W4 Games, RAWRLAB Games, Lone Wolf Technology, Pineapple Works, Seaven Studio and Sickhead Games.
  - The filters cover Switch, Switch 2, Xbox One, Xbox Series X/S, PS4 and PS5.
  - [Godot Console Support](https://godotengine.org/consoles/)
- GameDiscoverCo: "Godot console is still a little messy… since you probably need to use third-party middleware ports." — [GameDiscoverCo](https://newsletter.gamediscover.co/p/hows-pc-game-engine-usage-changing)

### Inferences
- For the stated plan (Windows first, then possibly Linux, Steam Deck and macOS, with consoles not a priority), both engines meet every requirement at $0 engine cost. The fixed external costs are the same for both: $100 Steam Direct per app, an Apple Developer membership for notarized macOS builds, and optionally a Windows code-signing certificate.
- If consoles become a goal, the paths differ. Unity requires Pro, which a sub-$200K team could buy voluntarily; it is not forced by revenue. Godot requires third-party middleware or porting fees. Both require platform-holder approval and devkits. This is a later-stage cost question, not a blocker.
- Steam Deck runs Linux (Proton or native). Both engines produce native Linux builds. Specific Deck-verification behaviour is outside this scope.

### Gaps
- W4 Games' current middleware pricing was not extracted. The W4 page was downloaded but not parsed for prices.
- Apple Developer Program fee and current Windows code-signing certificate costs were not verified from primary sources this session.
- Unity's Linux and Steam Deck specifics (e.g., Vulkan default, Proton notes) and Unity macOS notarization tooling were not checked.

---

## 6. Usage statistics (Steam, itch.io, game jams, surveys), 2024–2026

### Takeaway
Among released Steam games, Unity still dominates: about 49–51% of releases in 2024–2025, against Godot's 5–7%. Godot's share is rising fast (0.9% in 2020, 7.1% in 2025, 8.6% of unreleased games). Among higher-revenue games (>$500K), Unity's share rises to 53.7% and Godot's falls to 4.1%. In game jams Godot now leads: GMTK 2026 was 47% Godot versus 34% Unity, the first time Godot topped Unity.

### Cited Findings
- **GameDiscoverCo (17 Mar 2026)**, which scanned engines for 33,000+ Steam games using SteamDB-derived tech detection:
  - Godot went from "0.9% of all the games we scanned in 2020 to 7.1% in 2025… And it's 8.6% of all unreleased games we scanned."
  - Unity "has regularly had 50-51% of the total share of released games, dipping sliiightly to 49.4% by 2025."
  - Unreal grew from 15% (2020) to about 20% (2025).
  - "No obvious game engine" fell from 27% (2017) to 13% (2025).
  - In the >$500K lifetime revenue bucket: Unity 53.7%, Unreal 22.5%, Godot 4.1%.
  - Top 50 new Unreal games (last 12 months) grossed about $1.8B on Steam; the top 50 new Unity games grossed about $930M.
  - "Almost 50%" of top-charting new Unity titles were small-team projects (e.g., Schedule I, Megabonk, CloverPit).
  - Source: [GameDiscoverCo](https://newsletter.gamediscover.co/p/hows-pc-game-engine-usage-changing)
- **GDC State of the Game Industry 2026**: 42% of developers named Unreal and 30% named Unity as their "primary engine". GameDiscoverCo notes the survey likely skews toward bigger studios. — [GameDiscoverCo](https://newsletter.gamediscover.co/p/hows-pc-game-engine-usage-changing)
- **Video Game Insights** (13,000+ Steam games, 2024 releases):
  - By count: Unity 51%, Unreal 28%, Godot 5%, GameMaker 4%.
  - By revenue: custom engines 41%, Unreal 31%, Unity 26%.
  - "Godot is the only small engine that has grown significantly in recent years."
  - Unity "has started to lose some ground since 2021."
  - Source: [GameDev Reports / VGI, 10 Feb 2025](https://gamedevreports.substack.com/p/video-game-insights-game-engines)
- Methodology conflict: VGI puts Unreal at 28% of 2024 releases, while GameDiscoverCo puts Unreal at about 20% of 2025 releases. The samples and methods differ, so the figures should not be mixed. — [VGI](https://gamedevreports.substack.com/p/video-game-insights-game-engines); [GameDiscoverCo](https://newsletter.gamediscover.co/p/hows-pc-game-engine-usage-changing)
- **Godot's own count (June 2026)**: "Steam currently listing over 700 new Godot games published in 2026 so far… already over halfway to 2025's 1,200+ total… itch.io, which receives over 1,000 new Godot games every week." — [Godot 4.7 release page](https://godotengine.org/releases/4.7/)
- **GMTK Game Jam engine share** (Godot by year): 2022: 16%; 2023: 19%; 2024: 37%; 2025: 39%; 2026: **47%** (about 4,900 games). Unity in 2026 had 34% (about 3,600 games), "for the previous nine years straight, most developers used the Unity engine". GameMaker had 5% (498 games) and Unreal 3% (319 games). — [WN Hub, 29 Jul 2026](https://wnhub.io/news/engines/item-51600)
- Over the four years to 2025, Unity's GMTK share fell from 61% to 41%, while Godot rose from 13% to 39%. — [XorDev on X, quoting GMTK](https://x.com/XorDev/status/1952361213460922402); GMTK's own post: [Game Maker's Toolkit on Bluesky](https://bsky.app/profile/gamemakerstoolkit.com/post/3mrmx5mi3mk24)
- Small discrepancy: GameDiscoverCo cites 13% Godot at GMTK 2021, and WN Hub cites 16% for 2022. These are consistent (different years).

### Inferences
- Unity remains the safer statistical bet for shipped, commercially successful PC indie games, especially small-team breakouts. Godot's commercial footprint is real but still smaller and skewed toward lower-revenue titles.
- Godot's share among new and unreleased projects (8.6% on Steam, 47% at GMTK) points to strong momentum among exactly the solo and hobbyist developers this project resembles. Community help and hiring pools for Godot will likely keep growing through 2027.
- For FPS specifically, the data says Unreal is over-represented. Neither Unity nor Godot is the genre default, so FPS-specific engine-share data would not strongly favour either engine under comparison.

### Gaps
- SteamDB's technology pages (primary per-engine counts) were blocked (HTTP 403), so no direct SteamDB numbers are included.
- No 2026 itch.io-wide engine breakdown was found beyond Godot's "1,000+ per week" claim.
- No primary GDC 2026 survey document was fetched; the 42% and 30% figures come via GameDiscoverCo.
- No FPS-genre-specific engine share for Unity versus Godot was found.
