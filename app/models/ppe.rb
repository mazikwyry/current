class Ppe < ActiveRecord::Base


  attr_accessor :start_date, :end_date

  has_many :hourly_current_usages, dependent: :delete_all
  has_many :area_current_usages, dependent: :delete_all

  def usages area=nil
    usage_type == 'hourly' ? hourly_current_usages.order('date ASC') : (area ? area_current_usages.where(area: area).order('date ASC') : area_current_usages.order('date ASC'))
  end

  def check_areas
    self.update_attribute(:areas, self.usages.map{|u| u.area}.uniq)
  end

  def self.parse_usages json
    usages = JSON.parse(json)
    bad_types = []
    usages.each do |usage|
      case usage['type']
      when 'hourly'
        HourlyCurrentUsage.create(usage)
      when 'area'
        AreaCurrentUsage.create(usage)
      when 'range'
        HourlyCurrentUsage.create_from_range(usage)
      else
        bad_types << usage
      end
    end
  end

  def self.new_ppes content
    usages = JSON.parse(content)
    new_ppes = []
    wrong_type = []
    usages.each do |u|
      new_ppes << u['ppe'] unless Ppe.exists?(code: u['ppe'])
      wrong_type << u['ppe'] if Ppe.exists?(code: u['ppe'], usage_type: u['type']=='area' ? 'hourly' : 'area')
    end
    (new_ppes.present? || wrong_type.present?) ? {new: new_ppes.uniq, wrong: wrong_type.uniq}  : false
  end

  def get_usage start_date, end_date
    return {errors: ["Data początkowa powinna być wcześniejsza niż końcowa"]} if start_date > end_date
    case usage_type
    when 'hourly'

      start_date = (start_date.is_a?(Date) && start_date) || Date.parse(start_date)
      end_date = (end_date.is_a?(Date) && end_date) || Date.parse(end_date)
      #Get usages from rande and sum
      range_usages = self.usages.where("date >= :start_date AND date <= :end_date", :start_date => start_date, :end_date => end_date)
      sum = range_usages.sum(:daily_usage)
      
      #Get dates without usage
      usages_dates = range_usages.map{|u| u.date}
      date_range = (start_date..end_date)
      dates_without_usage = date_range.to_a - usages_dates

      #Sum states and add "-"" if there are empty days 
      states = range_usages.map{|u| u.daily_state}
      states << '-' if dates_without_usage.present?
      states = states.uniq.join(',')

      return {
        usages: range_usages, 
        sum: sum, 
        states: states, 
        start_date: start_date, 
        end_date: end_date, 
        dates_without_usage: dates_without_usage
      }

    when 'area'
      area_usage = {}
      errors = []
      areas.each do |a|
        errors << "Niewystarczająca ilość odczytów dla PPE #{code} dla strefy #{a}" and next if usages(a).count <= 1

        start_date = (start_date.is_a?(Date) && start_date) || Date.parse(start_date)
        end_date = (end_date.is_a?(Date) && end_date) || Date.parse(end_date)

        first_reading, second_reading = self.usages(a).limit(2)
        last_reading, prelast_reading = self.area_current_usages.where(area: a).order('date DESC').limit(2)

        # Check if start_date or end_date is out of readings range
        start_reading = first_reading if first_reading.date >= start_date
        finish_reading = second_reading if first_reading.date >= end_date 

        start_reading = prelast_reading if last_reading.date <= start_date
        finish_reading = last_reading if last_reading.date <= end_date

        unless start_reading
          start_reading = self.area_current_usages
                              .where("date <= :start_date and area = :area", 
                                      :area => a, 
                                      :start_date => start_date
                                    )
                              .order('date DESC')
                              .limit(1)
                              .first
        end
        unless finish_reading
          finish_reading = self.usages.where("date >= :end_date and area = :area", 
                                              :area => a, 
                                              :end_date => end_date)
                                      .limit(1)
                                      .first
        end


        mid_readings = self.area_current_usages
                              .where("date BETWEEN :start_date AND :end_date AND area = :area", 
                                      :area => a, 
                                      :start_date => start_date,
                                      :end_date => end_date
                                    )
                              .order('date DESC')
        
        all_readings = [start_reading, mid_readings, finish_reading].flatten.uniq.sort_by{|a| a.date}

        if(all_readings.length <= 2)
          daily_usage = (all_readings[1].usage - all_readings[0].usage)/(all_readings[0].date..all_readings[1].date).count
          usage = daily_usage*((start_date..end_date).count)
        else
          usage = 0
          (0..(all_readings.length-2)).each do |i|
            date_range = all_readings[i].date..all_readings[i+1].date
            daily_usage = (all_readings[i+1].usage - all_readings[i].usage)/(date_range).count
            # binding.pry
            if(i==0 && start_date < all_readings[i].date)
              usage += (start_date..all_readings[i].date).count*daily_usage
            elsif(i==(all_readings.length-2) && end_date > all_readings[i+1].date)
              usage += (all_readings[i+1].date..end_date).count*daily_usage
            end

            if date_range.cover?(start_date)
              usage += (start_date..all_readings[i+1].date).count*daily_usage
            elsif date_range.cover?(end_date)
              usage += (all_readings[i].date..end_date).count*daily_usage
            else
              usage += (all_readings[i+1].usage - all_readings[i].usage)
            end

          end
        end
        usage_date_range = (start_reading.date..finish_reading.date)
        state = case 
        when start_date>=start_reading.date && end_date<=finish_reading.date
          'R'
        when usage_date_range.cover?(start_date) || usage_date_range.cover?(end_date)
          'S'
        else
          'P'
        end
        area_usage[a] = {
          usages: [start_reading, finish_reading],
          usage: usage,
          state: state,
        }
      end
      return {
        area_usage: area_usage,
        total_usage: area_usage.inject(0){|sum, n| sum + n[1][:usage]},
        total_state: area_usage.map{|au| au[1][:state]}.uniq.join(','),
        start_date: start_date, 
        end_date: end_date,
        errors: errors
      }
    end
  end

  def get_usage_in_csv_row start_date, end_date
    usage = get_usage(start_date, end_date)
    case usage_type
      when 'hourly'
        [self.code, start_date.to_s, end_date.to_s, usage[:sum].round(3).to_s, usage[:states].to_s]  
      when 'area'
        return [self.code, start_date.to_s, end_date.to_s, 'BŁĄD: '+usage[:errors].join(',')] if usage[:errors].present?
        [self.code, start_date.to_s, end_date.to_s, usage[:total_usage].round(3).to_s, usage[:total_state].to_s, usage[:area_usage].keys.join(',').to_s, usage[:area_usage].first[1][:usages][1].date ]
    end
  end

  def get_monthly_usage start_date, end_date
    end_date = Date.parse(end_date+'-01').end_of_month
    start_date = Date.parse(start_date+'-01')
    no_months = (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
    monthly_usages = {}
    no_months.times do |month|
      monthly_usages[("m"+month.to_s).to_sym] = get_usage(start_date+month.months, start_date+(month+1).months)
    end
    monthly_usages
  end


  def self.generate_csv ppes, start_date, end_date
    CSV.generate do |csv|
      csv << ['PPE', 'Data Początkowa', 'Data Końcowa', 'Zużycie', 'Status', 'Strefy', 'Ostatni Pomiar']
      ppes.each do |ppe|
        csv << ppe.get_usage_in_csv_row(start_date, end_date)
      end
    end
  end 

  def self.sum_daily_hourly_usages date, area_ppes
    sum_row = [date]
    (0..24).each do |h|
      hourly = HourlyCurrentUsage.where(date: date).sum("CAST(hourly_usage -> '#{h}' ->> 'usage' AS DECIMAL)")
      area_usage = 0
      unless h==24
        area_ppes.each do |a|
          area_usage += (a.get_usage(date,date)[:total_usage]/24).round(3)
        end        
      end
      sum_row << hourly + area_usage
    end
    sum_row
  end

  def self.hourly_report start_date, end_date
    area_ppes = Ppe.where(usage_type: 'area')
    CSV.generate do |csv|
      csv << %w[Data 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]
      (Date.parse(start_date)..Date.parse(end_date)).each do |date|
        csv << Ppe.sum_daily_hourly_usages(date, area_ppes)
      end
    end
  end 

end
