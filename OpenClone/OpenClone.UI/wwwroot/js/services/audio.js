async function downloadAudioFile(url) {
    // STEP 1: Download the .wav file from the server
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error(`Failed to download audio file: ${response.statusText}`);
    }

    const arrayBuffer = await response.arrayBuffer();
    const audioBlob = new Blob([arrayBuffer], { type: 'audio/wav' });

    // Convert Blob to an object URL
    const audioUrl = URL.createObjectURL(audioBlob);

    // Create an Audio object
    const audio = new Audio(audioUrl);

    // Return the audio object
    return audio;
}

function getAudioFileLength(audio) {
    // STEP 2: Return the length of the audio file in milliseconds
    return new Promise((resolve, reject) => {
        audio.onloadedmetadata = () => {
            const duration = audio.duration * 1000; // duration in milliseconds
            resolve(duration);
        };

        audio.onerror = () => {
            reject(new Error('Failed to load audio metadata.'));
        };
    });
}

function playAudioFile(audio) {
    // STEP 3: Play the audio file
    audio.play().catch((error) => {
        console.error('Failed to play audio:', error);
    });
}

export { downloadAudioFile, getAudioFileLength, playAudioFile }