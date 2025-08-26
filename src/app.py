import re
import subprocess
from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

MATLAB_SCRIPT_PATH = "C:\\Users\\Dell\\Desktop\\Final\\ApplicationUpdated"

@app.route('/')
def index():
    return render_template('upload.html')


@app.route('/show-image', methods=['POST'])
def show_image():
    return render_template('image.html', image_displayed=True)


@app.route('/process', methods=['POST'])
def process_ecg():
    ecg_file = request.files['ecg-file']
    ecg_data = ecg_file.read()

    # Save the data to a temporary .mat file
    temp_file_path = "temp_data.mat"
    with open(temp_file_path, "wb") as temp_file:
        temp_file.write(ecg_data)
    #update_progress(25)
    # Run the MATLAB script
    matlab_command = f"matlab -batch \"addpath('{MATLAB_SCRIPT_PATH}'); main('{temp_file_path}')\""
    
    print("MATLAB Command:", matlab_command)  # Print the MATLAB command for debugging
    
    result = subprocess.run(matlab_command, shell=True, capture_output=True, text=True)
    #update_progress(50)
    print("MATLAB Output:")
    print(result.stdout)  # Print MATLAB output for debugging
    print("Matlab errors:")
    print(result.stderr)
    
    # Extract count_af from MATLAB script output
    #update_progress(75)
    hr_match = re.search(r'HR\s*=\s*([\d.]+)', result.stdout)
    hrv_match = re.search(r'HRV\s*=\s*([\d.]+)', result.stdout)
    qrs_match = re.search(r'QRS_dur\s*=\s*([\d.]+)', result.stdout)
    count_af_match = re.search(r'count_af\s*=\s*([\d.]+)', result.stdout)
    af_burden_match = re.search(r'AF_burden\s*=\s*([\d.]+)', result.stdout)
    print(count_af_match)
    
    normal_ranges = {
    "Heart rate": (60, 100),  
    "Heart Rate Variability": (0.1, float('inf')),
    "Average QRS duration": (0.05, 0.1)
    }

    def is_out_of_range(value, parameter):
        min_val, max_val = normal_ranges[parameter]
        return value < min_val or value > max_val

    
    #update_progress(100)
    if count_af_match and af_burden_match:
        print("fline")
        hr = float(hr_match.group(1))
        hrv = float(hrv_match.group(1))
        qrs = float(qrs_match.group(1))
        count_af = float(count_af_match.group(1))
        af_burden = float(af_burden_match.group(1))
        #print("line")
        result = jsonify({
        "result": f"""
            <br><br>
            Heart rate = <span style='color: {'red' if is_out_of_range(hr, "Heart rate") else 'white'}'>{hr} beats/min</span>&emsp;(Normal range: {normal_ranges["Heart rate"][0]}-{normal_ranges["Heart rate"][1]} beats/min)<br><br><br>
            Heart Rate Variability = <span style='color: {'red' if is_out_of_range(hrv, "Heart Rate Variability") else 'white'}'>{hrv} secs</span>&emsp;(Normal range: > {normal_ranges["Heart Rate Variability"][0]} secs)<br><br><br>
            Average QRS duration = <span style='color: {'red' if is_out_of_range(qrs, "Average QRS duration") else 'white'}'>{qrs} secs</span>&emsp;(Normal range: {normal_ranges["Average QRS duration"][0]}-{normal_ranges["Average QRS duration"][1]} secs)<br><br><br>
            Number of AF episodes(30s) = {count_af} <br><br><br>
            Percentage of AF = {af_burden}% 
        """
        })
        return result
        
    else:
        return jsonify({"result": "Error"})
    

if __name__ == '__main__':
    app.run(debug=True,port=3000)

