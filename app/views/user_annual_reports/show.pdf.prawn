prawn_document() do |pdf|
  image_path = Rails.root.to_s + '/lib/templates/documents'
  pdf.image "#{image_path}/unam.jpg", :at => [0, 750], :width => 100, :height => 114

  if defined?@stamped
    pdf.image "#{image_path}/received_stamp.jpg", :at => [400, 700], :width => 120
  end

  pdf.draw_text "Informe Anual de Actividades #{@year}", :at => [140, 710], :size => 20,  :style => :bold
  pdf.draw_text Salva::SiteConfig.institution('name'), :at => [220, 690], :size => 18,  :style => :bold
  pdf.move_down(100)

  pdf.text "Información general", :size => 16, :style => :bold, :final_gap => true
  pdf.text "\n"
  pdf.font 'Helvetica', :size => 12

  pdf.text "Nombre:", :style => :bold
  pdf.draw_text @profile.fullname, :style => :normal, :at => [160, pdf.cursor]

  pdf.text "Género:", :style => :bold
  pdf.draw_text @profile.gender, :style => :normal, :at => [160, pdf.cursor]

  pdf.text "Fecha de nacimiento:", :style => :bold
  pdf.draw_text @profile.birthdate, :style => :normal, :at => [160, pdf.cursor]

  pdf.text "Domicilio profesional:", :style => :bold
  pdf.text_box @profile.address, :style => :normal, :at => [160, pdf.cursor], :width => 370
  pdf.move_down(50)

  pdf.text "Teléfono:", :style => :bold
  pdf.draw_text @profile.phone, :style => :normal, :at => [160, pdf.cursor]

  pdf.text "Fax:", :style => :bold
  pdf.draw_text @profile.fax, :style => :normal, :at => [160, pdf.cursor]

  pdf.text "Correo electrónico:", :style => :bold
  pdf.draw_text @profile.email, :style => :normal, :at => [160, pdf.cursor]

  pdf.text "Identificación:", :style => :bold
  pdf.draw_text @profile.person_id, :style => :normal, :at => [160, pdf.cursor]

  pdf.text "Categoría:", :style => :bold
  pdf.draw_text @profile.category_name, :style => :normal, :at => [160, pdf.cursor]

  pdf.text "Adscripción:", :style => :bold
  pdf.draw_text @profile.adscription_name, :style => :normal, :at => [160, pdf.cursor]

  pdf.text "Número de trabajador:", :style => :bold
  pdf.draw_text @profile.worker_id, :style => :normal, :at => [160, pdf.cursor]

  if @profile.total_of_cites.to_i > 0
    pdf.text "Total de citas:", :style => :bold
    pdf.draw_text @profile.total_of_cites.to_s, :style => :normal, :at => [160, pdf.cursor]
  end

  unless @profile.responsible_academic.nil?
    pdf.text "Responsable académico:", :style => :bold
    pdf.draw_text @profile.responsible_academic.to_s, :style => :normal, :at => [160, pdf.cursor]
  end
  pdf.move_down(20)

  pdf.text "Breve descripción cualitativa de los logros más importantes del trabajo durante el año.", :style => :bold
  pdf.text "\n"
  counter = 0
  @annual_report.body.split("\n").each do |line|
    if (line =~ /^(\s)+\*/)
      pdf.text "#{line.sub(/^(\s)+\*/, '*')}", :align => :justify
    elsif (line =~ /^(\s)+\#/)
      counter +=1
      pdf.text "#{counter}. #{line.sub(/^(\s)+\#/, '')}", :align => :justify
    else
      pdf.text line, :align => :justify
    end
  end
  pdf.move_down(20)

  @report_sections.each do |section|
    pdf.text section[:title].to_s, :size => 16, :style => :bold, :final_gap => true
    pdf.text "\n"
    section[:subsections].each do |subsection|
      pdf.text subsection[:title].to_s, :size => 14, :style => :bold, :final_gap => true
      pdf.text "\n"

      counter = 1
      subsection[:collection].each do |record|
        pdf.text [counter, record].join('. ') + '.', :size => 12, :align => :justify
        counter += 1
      end
      pdf.text "\n" if counter > 1
    end
  end

  footer = "SALVA - Plat. Inf. Curric. a #{I18n.localize(Time.now, :format => :long).downcase}"
  pdf.font "Times-Roman", :size => 8, :style => :italic
  pdf.number_pages [footer, "#{@profile.email} desde la dirección #{@remote_ip}"].join(', '), :at => [pdf.bounds.left, 0]
  pdf.number_pages ["Página <page> de <total>"].join(', '), :at => [pdf.bounds.right - 55, 0]

  if defined? @signature
    pdf.font "Times-Roman", :size => 8, :style => :italic
    pdf.number_pages "Firma digital:", [pdf.bounds.left, -12]
    pdf.font "Times-Roman", :size => 8, :style => :normal
    pdf.draw_text @signature, :style => :normal, :at => [pdf.bounds.left + 50, -12]
  end
end
