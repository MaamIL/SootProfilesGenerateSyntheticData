import matlab.engine
from scipy.io import savemat, loadmat
import os
import random
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.widgets import CheckButtons
from matplotlib.path import Path
import cv2
from PIL import Image
import shutil
    
def save_text_to_file(filename, text):
    """Save the given text to a .txt file."""
    with open(filename, 'w') as file:
        file.write(text)
    print(f"Text saved to {filename}")

def save_csv(filename, data):
    """Save data to a CSV file."""
    np.savetxt(filename, data, delimiter=",", fmt="%.6f")
    print(f"Matrix saved to {filename}")
    
def generate_data():
    # Start MATLAB engine
    eng = matlab.engine.start_matlab()

    # Add the path to the MATLAB files
    eng.addpath(os.path.abspath("matlabfiles"))

    h_maxFv = random.randint(200,400) #random height for max fv
    h_top = random.randint(200,400) + h_maxFv #random height for top flame
    print("h_maxFv:", h_maxFv, "\th_top:", h_top)

    # Generate data using MATLAB functions
    print("~~~~~~~~~~~~~~~~~")
    print("Fv- Generating data...\n~~~~~~~~~~~~~~~~~")
    fbase  = np.array(eng.generatef(1))  
    print("fbase  - generatef(1):", fbase.size, max(fbase))    
    fmaxFv  = np.array(eng.generatef(4))  
    print("fmaxFv  - generatef(4):", fmaxFv.size, max(fmaxFv))    
    ftop  = np.array(eng.generatef(7))  
    print("ftop  - generatef(7):", ftop.size, max(ftop))
    print("~~~~~~~~~~~~~~~~~")
    print("T- Generating data...\n~~~~~~~~~~~~~~~~~")
    tbase  = eng.generateT(1)
    tbase = np.array(tbase).T #convert to numpy array
    print("tbase  - generateT(1):", tbase.size, max(tbase))    
    tmaxFv  = eng.generateT(4)
    tmaxFv = np.array(tmaxFv).T #convert to numpy array
    print("tmaxFv  - generateT(4):", tmaxFv.size, max(tmaxFv))    
    ttop  = eng.generateT(7)
    ttop = np.array(ttop).T #convert to numpy array
    print("ttop  - generateT(7):", ttop.size, max(ttop))
    print("~~~~~~~~~~~~~~~~~")

    # Quit MATLAB engine
    eng.quit()
    return h_maxFv, h_top, fbase, fmaxFv, ftop, tbase, tmaxFv, ttop
  
def create_interpolated_matrix(base, maxFv, top, h_maxFv, h_top, countour, ind, fv_t, fbase=None):
    # Define the dimensions of the matrix
    width = len(base) + 50 #TODO: if T- max(len(base), len(maxFv), len(top)) + 50
    height = h_top + 10

    if (fv_t == "Fv"):
        # Initialize the matrix with zeros
        matrix = np.zeros((height, width))
    elif (fv_t == "T"):
        # Initialize the matrix with ones
        matrix = np.full((height, width), 300)

    # Define the flame contour
    line_points = [(len(base), 0), (len(maxFv), h_maxFv), (len(top), h_top)]
    line_mask = np.zeros((height, width), dtype=np.uint8)
    for i in range(len(line_points)-1):
        pt1 = tuple(map(int, line_points[i]))
        pt2 = tuple(map(int, line_points[i+1]))
        cv2.line(line_mask, pt1, pt2, 1, thickness=1)
    
    # Fill the matrix with interpolated values
    for y in range(height):
        for x in range(width):
            # Check if the point is not inside the contour- skip it
            if countour is not None and not countour.contains_point((x, y)):
                continue
            if y == 0 and x < len(base): #insert fbase values
                matrix[y, x] = base[x].item()
            elif y == h_maxFv and x < len(maxFv): #insert fmaxFv values 
                matrix[y, x] = maxFv[x].item()
            elif y == h_top and x < len(top): #insert ftop values
                matrix[y, x] = top[x].item()
            elif line_mask[y, x] == 1:
                matrix[y, x] = 0.1 if fv_t == "Fv" else 300 
            elif y < h_maxFv:    # Base region
                weight = (y - 0) / (h_maxFv-0)
                if fv_t == "Fv":
                    if x < len(maxFv):                      
                        matrix[y, x] = (1 - weight) * base[x].item() + weight * maxFv[x].item()
                    elif matrix[y, x] == 0:
                        matrix[y, x] = (1 - weight) * base[x].item() + weight * 0.1
                elif fv_t == "T":
                    if x < len(fbase):                      
                        matrix[y, x] = (1 - weight) * base[x].item() + weight * maxFv[x].item()
                    elif matrix[y, x] == 300:
                        matrix[y, x] = (1 - weight) * 300 + weight * maxFv[x].item()
            elif h_maxFv < y < h_top:  # Middle region
                weight = (y - h_maxFv) / (h_top - h_maxFv)
                if fv_t == "Fv":
                    if x < len(top):
                        matrix[y, x] = (1 - weight) * maxFv[x].item() + weight * top[x].item()
                    elif matrix[y, x] == 0:
                        matrix[y, x] = (1 - weight) * maxFv[x].item() + weight * 0.1
                elif fv_t == "T":
                    if x < len(fbase):
                        matrix[y, x] = (1 - weight) * maxFv[x].item() + weight * top[x].item()
                    elif matrix[y, x] == 300:
                        matrix[y, x] = (1 - weight) * 300 + weight * top[x].item()


    print(f"{fv_t} Matrix shape:", matrix.shape)
    save_csv(os.path.join(str(ind),f"{fv_t}_interpolated_matrix.csv"), matrix)
    return matrix

def plot_matrix(matrix, savefig, ind, fv_t):
    """
    Plot the interpolated matrix with a contour line and a checkbox to toggle the contour visibility.
    """
    # Create the plot
    fig, ax = plt.subplots(figsize=(4, 6))
    plt.subplots_adjust(left=0.2)  # Leave space on the left for the checkbox

    # Show the interpolated matrix
    img = ax.imshow(matrix, extent=[0, matrix.shape[1], 0, matrix.shape[0]], origin='lower', cmap='hot', alpha=0.7)
    cbar = plt.colorbar(img, ax=ax, label='Interpolated Values')

    # Plot the contour initially (will be toggled)
    [line_plot] = ax.plot(x_coords, y_coords, marker='o', linestyle='-', color='b', label='Flame Contour')

    # # Add legend
    # legend = ax.legend(loc='upper left', bbox_to_anchor=(1.05, 1))

    # Add grid, labels
    ax.set_title(f"Flame {fv_t}")
    ax.set_xlabel("Length")
    ax.set_ylabel("Height")
    ax.grid(True)

    # Define toggle function
    def toggle_contour():
        visible = not line_plot.get_visible()
        line_plot.set_visible(visible)
        # legend.set_visible(visible)
        plt.draw()
    
    if (savefig):        
        plt.savefig(os.path.join(str(ind),f"{fv_t}_flame_plot_contour.png"), dpi=300)  # Save the figure as a PNG file
        line_plot.set_visible(False)  # Hide the contour line in the saved figure
        plt.draw()
        plt.savefig(os.path.join(str(ind),f"{fv_t}_flame_plot_noContour.png"), dpi=300)  # Save the figure as a PNG file
        plt.close()
    else:
        # Create check buttons
        rax = plt.axes([0.02, 0.5, 0.15, 0.1])  # [left, bottom, width, height]
        check = CheckButtons(rax, ['Show Contour'], [True])
        check.on_clicked(toggle_contour)
        plt.show()
        plt.close()

def is_data_ok(h_maxFv, h_top, fbase, fmaxFv, ftop, tbase, tmaxFv, ttop):
    """
    Check if the data is valid according to the specified conditions.
    """
    # Check if the data meets the conditions
    if [h_maxFv, h_top, fbase.tolist(), fmaxFv.tolist(), ftop.tolist(), tbase.tolist(), tmaxFv.tolist(), ttop.tolist()] in prev_run:
        #if I already have these values, skip it
        print("Same Data was previously generated, need to regenrate")
        return False
    elif (len(fbase)<=len(fmaxFv) or len(fmaxFv)<=len(ftop)):
        #if the length of fbase is less than fmaxFv or fmaxFv is less than ftop, skip it
        print(f"Length of fbase is less than fmaxFv or fmaxFv is less than ftop, need to regenrate ({len(fbase)},{len(fmaxFv)},{len(ftop)})")
        return False
    elif (max(fbase)>=max(fmaxFv) or max(ftop)>=max(fmaxFv)):
        #if the max value of fbase is greater than fmaxFv or ftop is greater than fmaxFv, skip it
        print(f"Max value of fbase is greater than fmaxFv or ftop is greater than fmaxFv, need to regenrate ({max(fbase)},{max(fmaxFv)},{max(ftop)})")
        return False
    elif all(len(arr) < len(fbase) for arr in [tbase, tmaxFv, ttop]):
        #if the length of any of the temperature vectors is less than fbase, skip it
        print(f"Length of tbase/tmaxFv/ttop is less than fbase, need to regenrate ({len(tbase)}/{len(tmaxFv)}/{len(ttop)}, {len(fbase)})")
        return False
    # elif (len(tbase)<=len(tmaxFv) or len(tmaxFv)<=len(ttop)):
    #     #if the length of tbase is less than tmaxFv or tmaxFv is less than ttop, skip it
    #     print(f"Length of tbase is less than tmaxFv or tmaxFv is less than ttop, need to regenrate ({len(tbase)},{len(tmaxFv)},{len(ttop)})")
    #     return False
    # elif (max(tbase._data)>=max(tmaxFv) or max(ttop)>=max(tmaxFv)):
    #     #if the max value of tbase is greater than tmaxFv or ttop is greater than tmaxFv, skip it
    #     print(f"Max value of tbase is greater than tmaxFv or ttop is greater than tmaxFv, need to regenrate ({max(tbase)},{max(tmaxFv)},{max(ttop)})")
    #     return False
    return True

def create_sootCalculationmat(fvmatrix, tmatrix, r, z, ind):
    """
    Create a sootCalculation.mat file with the data.
    """
    # Save the matrices into a .mat file
    sootCalculation_data = {
        "T": tmatrix.astype(np.float64),
        "fv": fvmatrix.astype(np.float64),
        "r": r.astype(np.float64),
        "z": z.astype(np.float64)
    }
    output_file = os.path.join(str(ind), "sootCalculation.mat")
    savemat(output_file, sootCalculation_data)
    print(f"SootCalculation.mat file saved to {output_file}") 
    return output_file

def create_rgb_image_matlab(sootCalculationmat_file, ind):
    """
    Create a RGB image from the T and Fv matrices using MATLAB.
    """
    # Start MATLAB engine
    eng = matlab.engine.start_matlab()

    # Add the path to the MATLAB files
    eng.addpath(os.path.abspath("sootImageMatlab"))

    # Call the MATLAB function to create the RGB image
    currentSubDir = os.path.join(os.getcwd(),str(ind))
    np.array(eng.run(currentSubDir, nargout=0)) 
    # Quit MATLAB engine
    eng.quit()
    
    # Load CFD image from CFDImage.mat
    cfd_mat = loadmat(os.path.join(currentSubDir, "CFDImage.mat"))
    image_array = cfd_mat["CFDImage"].astype(np.float32)
    image_array = (image_array/np.max(image_array))
    image = Image.fromarray((image_array * 255).astype(np.uint8)).convert("RGB")
    
    # # Save the RGB image as a PNG file
    output_file = os.path.join(str(ind), "flame_CFDImage_image.png")
    image.save(output_file)
    print(f"RGB image saved to {output_file}")

if __name__ == "__main__":
    prev_run = []
    i = 9975
    while i <= 12000:
        try:
            h_maxFv, h_top, fbase, fmaxFv, ftop, tbase, tmaxFv, ttop = generate_data()
            # Generate data until the condition is met (and its not the same as previous run)
            while not(is_data_ok(h_maxFv, h_top, fbase, fmaxFv, ftop, tbase, tmaxFv, ttop)):
                    print("~~~~~~~~~~\nGenerate data until the condition is met")
                    h_maxFv, h_top, fbase, fmaxFv, ftop, tbase, tmaxFv, ttop = generate_data()
            print("~~~~~~~~~~Done. condition is met!")
            prev_run.append([h_maxFv, h_top, fbase, fmaxFv, ftop, tbase, tmaxFv, ttop])
            os.makedirs(str(i), exist_ok=True)  # Create a directory for each run
            
            #save and manipulate data for Fv
            print("\nSave and manipulate data for Fv\n~~~~~~~~~~~~~~~~~")
            save_csv(os.path.join(str(i),"fbase.csv"), fbase)
            save_csv(os.path.join(str(i),"fmaxFv.csv"), fmaxFv)
            save_csv(os.path.join(str(i),"ftop.csv"), ftop)
            
            #create lines for flame contour
            lines = [(0,0), (len(fbase), 0), (len(fmaxFv), h_maxFv), (len(ftop), h_top), (0,h_top), (0,0)]
            fvcontour = Path(lines) #create a path for the contour
            # Extract x and y coordinates
            x_coords, y_coords = zip(*lines)

            # Generate the interpolated matrix
            fvmatrix = create_interpolated_matrix(fbase, fmaxFv, ftop, h_maxFv, h_top, fvcontour, i, "Fv")
            
            # plot
            plot_matrix(fvmatrix, True, i, "Fv")
            
            #save and manipulate data for T
            print("\nSave and manipulate data for T\n~~~~~~~~~~~~~~~~~")
            save_csv(os.path.join(str(i),"tbase.csv"), tbase)
            save_csv(os.path.join(str(i),"tmaxFv.csv"), tmaxFv)
            save_csv(os.path.join(str(i),"ttop.csv"), ttop)
            
            #create lines for flame contour
            lines = [(0,0), (len(tbase), 0), (len(tmaxFv), h_maxFv), (len(ttop), h_top), (0,h_top), (0,0)]
            tcontour = Path(lines) #create a path for the contour
            # Extract x and y coordinates
            x_coords, y_coords = zip(*lines)

            # Generate the interpolated matrix
            tmatrix = create_interpolated_matrix(tbase, tmaxFv, ttop, h_maxFv, h_top, fvcontour, i, "T", fbase)
            # Clip tmatrix to the size of fvmatrix
            tmatrix = tmatrix[:fvmatrix.shape[0], :fvmatrix.shape[1]]
            # Set values in tmatrix to 300 where fvmatrix < 0.1
            # tmatrix[fvmatrix < 0.1] = 300
            print("New T Matrix shape:", tmatrix.shape)
            # plot
            plot_matrix(tmatrix, True, i, "T")
            
            #run MATLAB script to generate flame RGB image from T and Fv matrices
            print("~~~~~~~~~~~~~~~~~")

            # #create a sootCalculation.mat file (fv, t, r, z) with the data
            r =  np.arange(start=0, stop=0.0662 * (min(fvmatrix.shape[0], fvmatrix.shape[1])), step=0.0662)
            r = r[:min(fvmatrix.shape[0], fvmatrix.shape[1])] #Because of rounding issues, every once in a smaple r is larger by 1 than the matrix size. This raises an error in matlab code. I clipped it to the size of r in any case.
            z = np.arange(start=0, stop=0.0662 * (max(fvmatrix.shape[0], fvmatrix.shape[1])), step=0.0662)
            z = z[:max(fvmatrix.shape[0], fvmatrix.shape[1])] #Because of rounding issues, every once in a smaple z is larger by 1 than the matrix size. This raises an error in matlab code. I clipped it to the size of z in any case.
            print("T Matrix shape:", tmatrix.shape, "Fv Matrix shape:", fvmatrix.shape)
            print("r shape:", r.shape, "z shape:", z.shape)
            sootCalculation_mat_file = create_sootCalculationmat(fvmatrix, tmatrix, r, z, i)
            # #create an RGB image of flame from T and Fv matrices
            create_rgb_image_matlab(sootCalculation_mat_file, i)
            
            #save info to txt file
            text = f"""
            h_maxFv: {h_maxFv}
            h_top: {h_top}
            Fv Data:
            fbase  - generatef(1): {fbase.size} \tmax: {max(fbase)}
            fmaxFv  - generatef(4): {fmaxFv.size} \tmax: {max(fmaxFv)}
            ftop  - generatef(7): {ftop.size} \tmax: {max(ftop)}
            Fv Matrix shape: {fvmatrix.shape}
            Fv Flame contour: {fvcontour}
            T Data:
            tbase  - generatet(1): {tbase.size} \tmax: {max(tbase)}
            tmaxFv  - generatet(4): {tmaxFv.size} \tmax: {max(tmaxFv)}
            ttop  - generatet(7): {ttop.size} \tmax: {max(ttop)}
            T Matrix shape: {tmatrix.shape}
            T Flame contour: {tcontour}
            r shape: {r.shape}
            z shape: {z.shape}
            """
            save_text_to_file(os.path.join(str(i),"info.txt"), text)
            i += 1
        except Exception as e:
            print(f"An error occurred: {e}")
            # If an error occurs, delete the directory and continue to the next iteration
            if os.path.exists(str(i)):
                shutil.rmtree(str(i))
        finally:
            # Clean up and close any resources if needed
            pass
        
