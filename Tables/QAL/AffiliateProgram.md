# Affiliate Program

This program is for affiliates who want to promote our products and earn commissions on sales. By joining our affiliate program, you can share unique referral links with your audience and receive a percentage of the sales generated through those links.

## Benefits of Joining

- Earn competitive commissions on sales
- Access to marketing materials and resources
- Real-time tracking of your referrals and earnings
- Dedicated support from our affiliate team
- Opportunities for bonuses and incentives
- Flexible payout options
- No cost to join
- Ability to promote a wide range of products
- Regular updates on new products and promotions
- Access to exclusive affiliate-only promotions and discounts
- Opportunity to collaborate on special campaigns and events
- Build a long-term partnership with our brand
- Opportunity to grow your audience and increase your influence in your niche
- Ability to leverage our brand reputation and customer base to boost your own credibility and sales
- Access to a supportive community of fellow affiliates for networking and collaboration
- Regular training and educational resources to help you succeed as an affiliate marketer

---

## How the Tracking System Works

The affiliate tracking system lives in the **AFL** (Affiliate Marketing) schema in the database. Six tables work together to track every step from ad click to lead conversion.

### Table Overview

| Table | Schema | Purpose |
|---|---|---|
| `MediaPlatforms` | AFL | Lookup of supported ad platforms (LinkedIn, Facebook, Instagram, TikTok, X, YouTube) |
| `Affiliates` | AFL | Registered affiliates, each tied to a Dealer with a unique `AffiliateCode` |
| `AffiliateCampaigns` | AFL | Named campaigns created by an affiliate for a specific dealer |
| `CampaignPlacements` | AFL | One placement per platform per campaign — holds the unique `TrackingToken` |
| `TokenClicks` | AFL | Immutable log of every click on a tracked ad URL |
| `LeadAttributions` | AFL | Links a converted lead (`QAL.Leads`) back to the placement and click that drove it |

### Data Flow

```
1. Affiliate registers
   AFL.Affiliates  (AffiliateCode = "JSMITH", tied to a Dealer)

2. Affiliate creates a campaign
   AFL.AffiliateCampaigns  (e.g., "Summer 2026 Solar Promo")

3. Affiliate posts an ad on a platform
   AFL.CampaignPlacements  → generates TrackingToken (e.g., "AFL-LI-00042")
                             token = AffiliateCode + PlatformCode + PlacementID
                             token is embedded in the ad URL: ?afl=AFL-LI-00042

4. Prospect clicks the ad
   AFL.TokenClicks  ← web layer records the click, stores SessionId

5. Prospect submits a lead form
   QAL.Leads  ← lead is created in the existing leads pipeline

6. System attributes the lead to the placement
   AFL.LeadAttributions  ← links QAL.Leads → CampaignPlacement → TokenClick
                            IsConverted on TokenClicks is flipped to 1
```

### Token Format

Tracking tokens follow the pattern `AFL-{PlatformCode}-{PlacementID}`:

- `AFL-LI-00042` → LinkedIn placement #42
- `AFL-FB-00007` → Facebook placement #7
- `AFL-IG-00123` → Instagram placement #123

Platform codes come from `AFL.MediaPlatforms.MediaPlatformCode` (e.g., `LI`, `FB`, `IG`, `TT`, `X`, `YT`).

### Attribution Rules

- Each lead can only have **one** attribution (`UQ_LeadAttributions_LeadId`).
- `TokenClickId` is nullable — if click tracking was unavailable but the token was captured from the form, the lead can still be attributed to the placement.
- Commission rates are stored per affiliate (`AFL.Affiliates.CommissionRate`) as a decimal (e.g., `0.0500` = 5%).

### External Dependencies

- `ACC.Dealers` — affiliates and campaigns are scoped to a specific dealer
- `QAL.Leads` — the lead pipeline that receives the converted prospects 