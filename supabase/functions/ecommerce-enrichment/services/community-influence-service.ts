// Community Influence Enrichment Service
// Phase 21 Section 2: Core Endpoints

import type {
  CommunityInfluenceRequest,
  CommunityInfluenceData,
  CommunityInfluencePatterns,
  InfluenceScore,
  InfluenceNetwork,
  AI2AIInsights,
  PurchaseBehavior,
  CommunityDrivenPurchases,
  TrendSetterScore,
  ViralPotential,
  SocialSharingTendency,
  MarketingImplications,
  RecommendedMarketingStrategy,
  MarketSegmentMetadata,
} from '../models.ts'

export class CommunityInfluenceService {
  constructor(private supabase: any) {}

  async getCommunityInfluence(
    request: CommunityInfluenceRequest
  ): Promise<CommunityInfluenceData> {
    const { user_segment, product_category } = request

    // Ensure segment exists
    await this.ensureSegmentExists(user_segment)

    // Aggregate AI2AI insights
    const { data: ai2aiData, error: ai2aiError } = await this.supabase.rpc(
      'aggregate_ai2ai_insights',
      { p_segment_id: user_segment.segment_id }
    )

    if (ai2aiError) {
      // If function doesn't exist or table doesn't exist, return default data
      if (ai2aiError.message?.includes('does not exist') || ai2aiError.message?.includes('relation')) {
        console.warn(`Database tables not available, returning default AI2AI data: ${ai2aiError.message}`)
        return this.getDefaultInfluenceData(user_segment, product_category)
      }
      throw new Error(`Failed to aggregate AI2AI insights: ${ai2aiError.message}`)
    }

    if (!ai2aiData || ai2aiData.error) {
      // If no data available, return defaults instead of error
      console.warn(`No AI2AI data available for segment ${user_segment.segment_id}, returning defaults`)
      return this.getDefaultInfluenceData(user_segment, product_category)
    }

    // Parallelize independent calculations for better performance
    const [influencePatterns, purchaseBehavior] = await Promise.all([
      this.calculateInfluencePatterns(user_segment, ai2aiData),
      this.calculatePurchaseBehavior(user_segment, ai2aiData),
    ])

    // Generate marketing implications (depends on above calculations)
    const marketingImplications = await this.generateMarketingImplications(
      influencePatterns,
      purchaseBehavior,
      product_category
    )

    return {
      community_influence_patterns: influencePatterns,
      purchase_behavior: purchaseBehavior,
      marketing_implications: marketingImplications,
      market_segment_metadata: {
        sample_size: ai2aiData.sample_size || 0,
        data_freshness: new Date().toISOString(),
        network_analysis_version: '1.0',
      },
    }
  }

  private async ensureSegmentExists(user_segment: any): Promise<void> {
    const { data: existing } = await this.supabase
      .from('market_segments')
      .select('segment_id')
      .eq('segment_id', user_segment.segment_id)
      .single()

    if (!existing) {
      await this.supabase.from('market_segments').insert({
        segment_id: user_segment.segment_id,
        segment_definition: user_segment,
        sample_size: 0,
      })
    }
  }

  private async calculateInfluencePatterns(
    user_segment: any,
    ai2aiData: any
  ): Promise<CommunityInfluencePatterns> {
    // Calculate influence score based on network metrics
    const avgCompatibility = ai2aiData.average_compatibility || 0.5
    const connectionFrequency = ai2aiData.connection_frequency || 'low'
    const uniqueUsers = ai2aiData.unique_users || 0

    // Influence score: combination of compatibility, frequency, and network size
    const influenceScore = Math.min(
      (avgCompatibility * 0.4) +
      (connectionFrequency === 'high' ? 0.3 : connectionFrequency === 'medium' ? 0.2 : 0.1) +
      (Math.min(uniqueUsers / 100, 1.0) * 0.3),
      1.0
    )

    // Calculate network metrics
    const totalConnections = ai2aiData.total_connections || 0
    const networkDensity = uniqueUsers > 0 ? totalConnections / (uniqueUsers * (uniqueUsers - 1) / 2) : 0
    const communityReach = Math.min(uniqueUsers / 1000, 1.0)

    return {
      influence_score: {
        value: influenceScore,
        interpretation: influenceScore > 0.7 ? 'High influence in community' :
                        influenceScore > 0.4 ? 'Moderate influence' :
                        'Low influence',
        confidence: 0.81,
      },
      community_size: uniqueUsers,
      influence_network: {
        direct_connections: Math.floor(totalConnections * 0.3), // Estimate
        indirect_connections: Math.floor(totalConnections * 0.7), // Estimate
        community_reach: communityReach,
        network_density: Math.min(networkDensity, 1.0),
      },
      ai2ai_insights: {
        average_compatibility: avgCompatibility,
        connection_frequency: connectionFrequency,
        learning_rate: ai2aiData.learning_rate || avgCompatibility,
      },
    }
  }

  private async calculatePurchaseBehavior(
    user_segment: any,
    ai2aiData: any
  ): Promise<PurchaseBehavior> {
    // Calculate community-driven purchases based on network metrics
    const avgCompatibility = ai2aiData.average_compatibility || 0.5
    const connectionFrequency = ai2aiData.connection_frequency || 'low'

    // High compatibility + high frequency = community-driven purchases
    const communityDriven = Math.min(
      (avgCompatibility * 0.5) +
      (connectionFrequency === 'high' ? 0.3 : connectionFrequency === 'medium' ? 0.2 : 0.1) +
      0.2, // Base community influence
      1.0
    )

    // Trend setter score: based on network position and compatibility
    const trendSetterScore = Math.min(
      (avgCompatibility * 0.4) +
      (connectionFrequency === 'high' ? 0.4 : connectionFrequency === 'medium' ? 0.3 : 0.2),
      1.0
    )

    // Viral potential: combination of influence and network size
    const viralPotential = Math.min(
      (communityDriven * 0.5) +
      (trendSetterScore * 0.3) +
      (Math.min((ai2aiData.unique_users || 0) / 500, 1.0) * 0.2),
      1.0
    )

    // Social sharing tendency: correlates with community engagement
    const socialSharingTendency = communityDriven * 0.9

    return {
      community_driven_purchases: {
        value: communityDriven,
        interpretation: `${Math.round(communityDriven * 100)}% influenced by community`,
        confidence: 0.79,
      },
      trend_setter_score: {
        value: trendSetterScore,
        interpretation: trendSetterScore > 0.7 ? 'High trend-setting potential' :
                        trendSetterScore > 0.4 ? 'Moderate trend-setting' :
                        'Low trend-setting',
        confidence: 0.82,
      },
      viral_potential: {
        value: viralPotential,
        interpretation: viralPotential > 0.7 ? 'High viral potential' :
                        viralPotential > 0.4 ? 'Moderate viral potential' :
                        'Low viral potential',
        confidence: 0.76,
      },
      social_sharing_tendency: {
        value: socialSharingTendency,
        interpretation: `${Math.round(socialSharingTendency * 100)}% likely to share purchases`,
        confidence: 0.74,
      },
    }
  }

  private async generateMarketingImplications(
    influencePatterns: CommunityInfluencePatterns,
    purchaseBehavior: PurchaseBehavior,
    productCategory?: string
  ): Promise<MarketingImplications> {
    const influenceScore = influencePatterns.influence_score.value
    const communityDriven = purchaseBehavior.community_driven_purchases.value
    const trendSetter = purchaseBehavior.trend_setter_score.value

    // Generate recommended marketing strategies
    const strategies: RecommendedMarketingStrategy[] = []

    // Community endorsement strategy
    if (communityDriven > 0.6) {
      strategies.push({
        strategy: 'community_endorsement',
        effectiveness: 0.85,
        reasoning: 'High community orientation + influence score',
      })
    }

    // Early adopter program
    if (trendSetter > 0.7) {
      strategies.push({
        strategy: 'early_adopter_program',
        effectiveness: 0.78,
        reasoning: 'High trend-setter score + novelty seeking',
      })
    }

    // Social proof
    if (communityDriven > 0.5) {
      strategies.push({
        strategy: 'social_proof',
        effectiveness: 0.72,
        reasoning: 'High community-driven purchases',
      })
    }

    // Influencer partnership
    if (influenceScore > 0.7 && trendSetter > 0.6) {
      strategies.push({
        strategy: 'influencer_partnership',
        effectiveness: 0.80,
        reasoning: 'High influence score + trend-setter potential',
      })
    }

    return {
      responds_to_community_endorsements: {
        value: communityDriven > 0.6,
        confidence: 0.87,
      },
      likely_to_share_purchases: {
        value: purchaseBehavior.social_sharing_tendency.value,
        confidence: 0.75,
      },
      influencer_potential: {
        value: influenceScore,
        interpretation: influenceScore > 0.7 ? 'High influencer potential' :
                        influenceScore > 0.4 ? 'Moderate influencer potential' :
                        'Low influencer potential',
        confidence: 0.80,
      },
      recommended_marketing_strategies: strategies,
    }
  }

  private getDefaultInfluenceData(user_segment: any, productCategory?: string): CommunityInfluenceData {
    // Return default data when actual data is not available
    return {
      community_influence_patterns: {
        influence_score: {
          value: 0.65,
          interpretation: 'Moderate influence in community (default estimate)',
          confidence: 0.75,
        },
        community_size: 100,
        influence_network: {
          direct_connections: 30,
          indirect_connections: 70,
          community_reach: 0.1,
          network_density: 0.3,
        },
        ai2ai_insights: {
          average_compatibility: 0.7,
          connection_frequency: 'medium',
          learning_rate: 0.7,
        },
      },
      purchase_behavior: {
        community_driven_purchases: {
          value: 0.6,
          interpretation: '60% influenced by community (default estimate)',
          confidence: 0.75,
        },
        trend_setter_score: {
          value: 0.65,
          interpretation: 'Moderate trend-setting potential (default estimate)',
          confidence: 0.75,
        },
        viral_potential: {
          value: 0.6,
          interpretation: 'Moderate viral potential (default estimate)',
          confidence: 0.75,
        },
        social_sharing_tendency: {
          value: 0.55,
          interpretation: '55% likely to share purchases (default estimate)',
          confidence: 0.75,
        },
      },
      marketing_implications: {
        responds_to_community_endorsements: {
          value: true,
          confidence: 0.75,
        },
        likely_to_share_purchases: {
          value: 0.55,
          confidence: 0.75,
        },
        influencer_potential: {
          value: 0.65,
          interpretation: 'Moderate influencer potential (default estimate)',
          confidence: 0.75,
        },
        recommended_marketing_strategies: [
          {
            strategy: 'community_endorsement',
            effectiveness: 0.75,
            reasoning: 'Default recommendation based on segment characteristics',
          },
          {
            strategy: 'social_proof',
            effectiveness: 0.7,
            reasoning: 'Default recommendation based on segment characteristics',
          },
        ],
      },
      market_segment_metadata: {
        sample_size: 0,
        data_freshness: new Date().toISOString(),
        network_analysis_version: '1.0',
      },
    }
  }
}
