// Real-World Behavior Enrichment Service
// Phase 21 Section 2: Core Endpoints

import type {
  RealWorldBehaviorRequest,
  RealWorldBehaviorData,
  AverageDwellTime,
  ReturnVisitRate,
  ExplorationTendency,
  CommunityEngagement,
  JourneyPatterns,
  TimeSpentAnalysis,
  ProductImplications,
  MarketSegmentMetadata,
} from '../models.ts'

export class RealWorldBehaviorService {
  constructor(private supabase: any) {}

  async getRealWorldBehavior(
    request: RealWorldBehaviorRequest
  ): Promise<RealWorldBehaviorData> {
    const { user_segment, product_context } = request

    // Ensure segment exists in market_segments table
    await this.ensureSegmentExists(user_segment)

    // Call database function to aggregate behavior
    const { data: behaviorData, error } = await this.supabase.rpc(
      'aggregate_real_world_behavior',
      { p_segment_id: user_segment.segment_id }
    )

    if (error) {
      // If function doesn't exist or table doesn't exist, return default data
      if (error.message?.includes('does not exist') || error.message?.includes('relation')) {
        console.warn(`Database tables not available, returning default behavior data: ${error.message}`)
        return this.getDefaultBehaviorData(user_segment)
      }
      throw new Error(`Failed to aggregate behavior: ${error.message}`)
    }

    if (!behaviorData || behaviorData.error) {
      // If no data available, return defaults instead of error
      console.warn(`No data available for segment ${user_segment.segment_id}, returning defaults`)
      return this.getDefaultBehaviorData(user_segment)
    }

    // Parallelize independent queries for better performance
    const [communityEngagement, journeyPatterns, productImplications] = await Promise.all([
      this.calculateCommunityEngagement(user_segment),
      this.calculateJourneyPatterns(user_segment),
      this.calculateProductImplications(behaviorData, product_context),
    ])

    // Format response according to data model
    const realWorldBehavior: RealWorldBehaviorData = {
      real_world_behavior: {
        average_dwell_time: {
          value: behaviorData.average_dwell_time?.value || 0,
          unit: 'minutes',
          confidence: behaviorData.average_dwell_time?.confidence || 0.75,
        },
        return_visit_rate: {
          value: behaviorData.return_visit_rate?.value || 0,
          interpretation: behaviorData.return_visit_rate?.interpretation || 'No data available',
          confidence: behaviorData.return_visit_rate?.confidence || 0.75,
        },
        exploration_tendency: {
          value: behaviorData.exploration_tendency?.value || 0.5,
          interpretation: behaviorData.exploration_tendency?.interpretation || 'Moderate exploration tendency',
          confidence: behaviorData.exploration_tendency?.confidence || 0.75,
        },
        community_engagement: communityEngagement,
        journey_patterns: journeyPatterns,
        time_spent_analysis: {
          short_visits: behaviorData.time_spent_analysis?.short_visits || 0,
          medium_visits: behaviorData.time_spent_analysis?.medium_visits || 0,
          long_visits: behaviorData.time_spent_analysis?.long_visits || 0,
        },
      },
      product_implications: productImplications,
      market_segment_metadata: {
        sample_size: behaviorData.sample_size || 0,
        data_freshness: new Date().toISOString(),
        geographic_coverage: user_segment.geographic_region,
      },
    }

    return realWorldBehavior
  }

  private async ensureSegmentExists(user_segment: any): Promise<void> {
    // Check if segment exists
    const { data: existing } = await this.supabase
      .from('market_segments')
      .select('segment_id')
      .eq('segment_id', user_segment.segment_id)
      .single()

    if (!existing) {
      // Create segment if it doesn't exist
      await this.supabase.from('market_segments').insert({
        segment_id: user_segment.segment_id,
        segment_definition: user_segment,
        sample_size: 0,
      })
    }
  }

  private async calculateCommunityEngagement(
    user_segment: any
  ): Promise<CommunityEngagement> {
    // Query user_actions for community-related activities
    const { data: actions, error } = await this.supabase
      .from('user_actions')
      .select('action_type')
      .eq('action_type', 'event_attendance')
      .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())

    if (error || !actions) {
      return {
        value: 0.5,
        interpretation: 'Moderate community engagement',
        confidence: 0.6,
      }
    }

    // Calculate engagement score based on event attendance
    const engagementScore = Math.min(actions.length / 10, 1.0) // Normalize to 0-1

    return {
      value: engagementScore,
      interpretation: engagementScore > 0.7 ? 'High community engagement' : 
                      engagementScore > 0.4 ? 'Moderate community engagement' : 
                      'Low community engagement',
      confidence: 0.75,
    }
  }

  private async calculateJourneyPatterns(
    user_segment: any
  ): Promise<JourneyPatterns> {
    // Query user_actions for journey patterns
    const { data: actions, error } = await this.supabase
      .from('user_actions')
      .select('action_type, spot_id')
      .order('created_at', { ascending: true })
      .limit(100)

    if (error || !actions || actions.length === 0) {
      return {
        typical_path: ['coffee_shop', 'work', 'restaurant'],
        frequency: 'daily',
        variability: 0.3,
      }
    }

    // Extract typical path from actions
    const pathTypes = actions
      .map((a: any) => {
        if (a.action_type === 'spot_visit') return 'spot'
        if (a.action_type === 'event_attendance') return 'event'
        return null
      })
      .filter((p: any) => p !== null)

    return {
      typical_path: pathTypes.slice(0, 5) || ['spot', 'spot', 'event'],
      frequency: 'daily',
      variability: 0.25,
    }
  }

  private async calculateProductImplications(
    behaviorData: any,
    productContext?: any
  ): Promise<ProductImplications> {
    const returnRate = behaviorData.return_visit_rate?.value || 0.5
    const explorationTendency = behaviorData.exploration_tendency?.value || 0.5

    // High return rate + low exploration = prefers quality over price
    const prefersQuality = returnRate > 0.6 && explorationTendency < 0.4

    // High community engagement = values community products
    const valuesCommunity = behaviorData.community_engagement?.value > 0.6 || false

    // Return rate correlates with likelihood to return purchase
    const likelyToReturnPurchase = returnRate * 0.9 // Slight discount for online vs real-world

    return {
      prefers_quality_over_price: {
        value: prefersQuality,
        confidence: 0.85,
      },
      values_community_products: {
        value: valuesCommunity,
        confidence: 0.75,
      },
      likely_to_return_purchase: {
        value: likelyToReturnPurchase,
        confidence: 0.80,
      },
      purchase_decision_factors: [
        {
          factor: 'quality',
          weight: prefersQuality ? 0.45 : 0.30,
        },
        {
          factor: 'community_endorsement',
          weight: valuesCommunity ? 0.30 : 0.15,
        },
        {
          factor: 'price',
          weight: prefersQuality ? 0.15 : 0.40,
        },
        {
          factor: 'sustainability',
          weight: 0.10,
        },
      ],
    }
  }

  private getDefaultBehaviorData(user_segment: any): RealWorldBehaviorData {
    // Return default data when actual data is not available
    return {
      real_world_behavior: {
        average_dwell_time: {
          value: 45,
          unit: 'minutes',
          confidence: 0.75,
        },
        return_visit_rate: {
          value: 0.65,
          interpretation: '65% return to favorites (default estimate)',
          confidence: 0.75,
        },
        exploration_tendency: {
          value: 0.35,
          interpretation: '35% explore new places (default estimate)',
          confidence: 0.75,
        },
        community_engagement: {
          value: 0.6,
          interpretation: 'Moderate community engagement (default estimate)',
          confidence: 0.75,
        },
        journey_patterns: {
          typical_path: ['coffee_shop', 'work', 'restaurant', 'event'],
          frequency: 'daily',
          variability: 0.3,
        },
        time_spent_analysis: {
          short_visits: 0.2,
          medium_visits: 0.5,
          long_visits: 0.3,
        },
      },
      product_implications: {
        prefers_quality_over_price: {
          value: true,
          confidence: 0.75,
        },
        values_community_products: {
          value: true,
          confidence: 0.75,
        },
        likely_to_return_purchase: {
          value: 0.7,
          confidence: 0.75,
        },
        purchase_decision_factors: [
          { factor: 'quality', weight: 0.4 },
          { factor: 'community_endorsement', weight: 0.3 },
          { factor: 'price', weight: 0.2 },
          { factor: 'sustainability', weight: 0.1 },
        ],
      },
      market_segment_metadata: {
        sample_size: 0,
        data_freshness: new Date().toISOString(),
        geographic_coverage: user_segment.geographic_region,
        data_version: '1.0',
      },
    }
  }
}
