# Uncomment the next line to define a global platform for your project
 platform :ios, '13.0'

target 'PassportScanner' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!
  
  pod 'QKMRZScanner'
  pod 'NFCPassportReader', git:'https://github.com/AndyQ/NFCPassportReader.git'  

  target 'PassportScannerTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
