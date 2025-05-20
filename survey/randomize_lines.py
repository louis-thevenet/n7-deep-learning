import random

def randomize(filename):
    '''
    Updates the file by randomizing lines
    '''
    with open(filename, 'r') as file:
        lines = file.readlines()
    random.shuffle(lines)
    with open(filename, 'w') as file:
        file.writelines(lines)
    

if __name__ == "__main__":
    randomize("mix-proverbs-answer")